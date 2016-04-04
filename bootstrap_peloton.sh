#!/bin/sh

NUM_CORE=16
PELOTON_HOME=$PELOTON_HOME
# Clean up any existing peloton data directory
rm -rf data

pwd=`pwd`
# Rebuild and install
cd $PELOTON_HOME/build/
make -j$NUM_CORE
sudo make install
cd $pwd

# Setup new peloton data directory
initdb data

# Copy over the peloton configuration file into the directory
sed 's/peloton_logging_mode aries/peloton_logging_mode invalid/g' $PELOTON_HOME/scripts/oltpbenchmark/postgresql.conf > data/postgresql.conf

# Kill any existing peloton processes
pkill -9 peloton
pg_ctl -D data stop

# Clean up any existing peloton log
rm data/pg_log/peloton.log

# Start the peloton server
peloton -D ./data & # > /dev/null 2>&1 &

# Wait for a moment for the server to start up...
sleep 5

# Create a "postgres" user
createuser -r -s postgres

# Create a default database for psql
createdb $USER

# Create YCSB and TPC-C databases

echo "create database ycsb;" | psql postgres
echo "create database tpcc;" | psql postgres

echo "Peloton prepared"
pg_ctl -D ./data stop
