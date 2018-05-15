FROM openjdk:8-jdk-stretch
LABEL maintainer="Gunnar Beutner <gunnar@beutner.name>"

# Install OpenTSDB
ENV TSDB_VERSION 2.4.0RC2

RUN mkdir -p /opt/bin/

RUN mkdir /opt/opentsdb/
WORKDIR /opt/opentsdb/
RUN apt-get update && apt-get install -y build-essential wget git autoconf automake python gnuplot \
  && : Install OpenTSDB and scripts \
  && wget --no-check-certificate \
    -O v${TSDB_VERSION}.zip \
    https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip \
  && unzip v${TSDB_VERSION}.zip \
  && rm v${TSDB_VERSION}.zip \
  && cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  && echo "tsd.http.request.enable_chunked = true" >> src/opentsdb.conf \
  && echo "tsd.http.request.max_chunk = 16777216" >> src/opentsdb.conf \
  && cp src/opentsdb.conf /etc/ \
  && cp src/create_table.sh /usr/local/bin/tsdb-create-table \
  && ./build.sh \
  && cd build \
  && make install \
  && cd / \
  && rm -rf /opt/opentsdb \
  && apt-get purge -y build-essential git autoconf automake \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/cache/apt/*

#Install HBase and scripts
ENV HBASE_VERSION 1.4.4

RUN mkdir -p /data/hbase /root/.profile.d

RUN mkdir /opt/downloads && \
    cd /opt/downloads && \
    wget -O hbase-${HBASE_VERSION}.bin.tar.gz http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz && \
    tar xzvf hbase-${HBASE_VERSION}.bin.tar.gz && \
    mv hbase-${HBASE_VERSION} /opt/hbase && \
    rm -rf /opt/downloads

ADD docker/hbase-site.xml /opt/hbase/conf/
ADD docker/start_opentsdb.sh /opt/bin/
ADD docker/create_tsdb_tables.sh /opt/bin/
ADD docker/start_hbase.sh /opt/bin/
ADD docker/entrypoint.sh /opt/bin/

RUN for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
    do \
        sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
    done


RUN mkdir -p /etc/services.d/hbase /etc/services.d/tsdb
RUN ln -s /opt/bin/start_hbase.sh /etc/services.d/hbase/run
RUN ln -s /opt/bin/start_opentsdb.sh /etc/services.d/tsdb/run

EXPOSE 60000 60010 60030 4242 16010

VOLUME ["/data/hbase", "/tmp"]

CMD ["/opt/bin/entrypoint.sh"]
