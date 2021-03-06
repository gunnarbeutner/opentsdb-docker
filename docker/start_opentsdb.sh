#!/bin/bash
export TSDB_VERSION="::TSDB_VERSION::"
echo "Sleeping for 30 seconds to give HBase time to warm up"
sleep 30

if [ ! -e /opt/opentsdb_tables_created.txt ]; then
	echo "creating tsdb tables"
	bash /opt/bin/create_tsdb_tables.sh
	echo "created tsdb tables"
fi

echo "starting opentsdb"
tsdb tsd --port=4242 --staticroot=/usr/local/share/opentsdb/static --cachedir=/tmp --auto-metric --config=/etc/opentsdb.conf
