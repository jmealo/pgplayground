#!/bin/sh
sudo su
apt-get install -y python-software-properties python-setuptools wget ca-certificates git

# Add official PostgreSQL Apt Repository
wget -O - https://gist.githubusercontent.com/jmealo/0f1e2c9c4befe2b9eeb2/raw/1389e9d3e7327ef0a1cd26c9d1f4d479dfed18a3/apt.postgresql.org.sh | bash

apt-get install -y postgresql postgresql-contrib libpq-dev postgresql-server-dev-9.4

# Add ZFS repo
add-apt-repository ppa:zfs-native/stable
apt-get update
apt-get install ubuntu-zfs

#######################################################################
# TODO: Check if the pool is already created before we try to do this #
#######################################################################
# Create ZFS pool
zpool create -f tank mirror sdb sdc mirror sdd sde
zfs set compression=lz4 tank
zfs set atime=off tank

service postgresql stop
cp -r /var/lib/postgresql/9.4/main /tank
ln -s /tank /var/lib/postgresql/9.4/main
service postgresql start
#######################################################################

wget https://raw.githubusercontent.com/tiberiusteng/tools/master/arc_summary.py -O /usr/local/bin/arc_summary.py
chmod +x /usr/local/bin/arc_summary.py

# Install PGXN
easy_install pgxnclient

# Install development dependencies for postgres modules
apt-get install -y libyajl-dev libmysqld-dev protobuf-c-compiler libprotobuf-c0-dev libv8-dev

# Install PGXN modules
pgxn install mysql_fdw
pgxn install json_fdw
pgxn install cstore_fdw
pgxn install --testing cyanaudit
pgxn install quantile
pgxn install trimmed_aggregates
pgxn install weighted_mean
pgxn install plv8
pgxn install --testing temporal_tables
# TODO: redis-fdw didn't compile even with libhiredis-dev installed (https://gist.github.com/jmealo/a9271c47a08f783cb9bc)

