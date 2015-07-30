#!/bin/bash

if [[ whoami -ne "root" ]]; then
    echo "This script should not be run using sudo or as the root user"
    exit 1
fi

provision_ts=$(date +"%s")
provision_dir=$(pwd)
zpool_name="tank"

echo_failure() {
  printf "\e[31m ✘ ${1} \e[0m"
}

echo_success() {
  printf "\e[32m ✔ ${1} \e[0m"
}

# Use step(), try(), and next() to perform a series of commands and print
# [  OK  ] or [FAILED] at the end. The step as a whole fails if any individual
# command fails.
#
# Example:
#     step "Remounting / and /boot as read-write: "
#     try mount -o remount,rw /
#     try mount -o remount,rw /boot
#     next
step() {
    echo -n "$@"

    STEP_OK=0
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}

try() {
    local BG=1;

    [[ $1 == -- ]] && {       shift; }

    # Run the command.
    "$@"


    # Check if command failed and update $STEP_OK if so.
    local EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        STEP_OK=$EXIT_CODE
        [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$

        if [[ -n $LOG_STEPS ]]; then
            local FILE=$(readlink -m "${BASH_SOURCE[1]}")
            local LINE=${BASH_LINENO[0]}

            echo "$FILE: line $LINE: Command \`$*' failed with exit code $EXIT_CODE." >> "$LOG_STEPS"
        fi
    fi

    return $EXIT_CODE
}

next() {
    [[ -f /tmp/step.$$ ]] && { STEP_OK=$(< /tmp/step.$$); rm -f /tmp/step.$$; }
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo

    return $STEP_OK
}

is_installed() {
    dpkg-query -Wf'${db:Status-abbrev}' "$1" 2>/dev/null | grep -q '^i'
}

command_exists () {
    type "$1" &> /dev/null ;
}

pg_extension_exists () {
    if [ -f "/usr/lib/postgresql/9.4/lib/$1.so" ]; then
        return 0
    fi

    if [ -f "/usr/share/postgresql/9.4/extension/$1.control" ]; then
        return 0
    fi

    return 1
}

pgxn_install () {
    local file=$1
    local file=${2:-$file}

    export USE_PGXS=1

    if ! pg_extension_exists ${file}
    then
        echo "$file... installing"
        if [ -z "$3" ]; then
            pgxn install --yes $1
        else
            pgxn install --yes --$3 $1
        fi
    else
        echo "$file... already installed"
        return 0
    fi
}

is_mounted () {
	local FS=$(zfs get -H mounted "${@}")

	FS_REGEX="^${@}\s+mounted\s+yes\s+-"

	if [[ $FS =~ $FS_REGEX ]]; then
		return 0
	fi

	return 1
}

locale_set=$(locale | grep en_US.UTF-8)

if [ ! locale_set ]; then
    step "Setting locale: "
        for y in $(locale | cut -d '=' -f 2| sort |uniq ); do locale-gen $y; done
        try locale-gen "en_US.UTF-8"
        try dpkg-reconfigure locales
        try update-locale LANG=en_US.UTF-8
    next
fi

if ! command_exists "add-apt-repository" ] || ! is_installed "git" || ! is_installed "unzip" || ! is_installed "build-essential"
then
    step "Installing packages required to install other packages: "
        try apt-get install -y python-software-properties python-setuptools wget curl unzip nano ca-certificates git sudo build-essential
        try git config --global core.editor "nano"
    next
fi

if ! is_installed "libhiredis-dev"
then
    step "Installing PostgreSQL: "
        try wget -O - https://gist.githubusercontent.com/jmealo/0f1e2c9c4befe2b9eeb2/raw/1389e9d3e7327ef0a1cd26c9d1f4d479dfed18a3/apt.postgresql.org.sh | bash
        try apt-get install -y postgresql postgresql-contrib libpq-dev postgresql-server-dev-9.4 postgresql-plperl-9.4 libhiredis-dev
    next
fi

if [ -b "/dev/sdb" ] && [ -b "/dev/sdc" ] && [ -b "/dev/sdd" ] && [ -b "/dev/sde" ]
then

    if ! is_installed "ubuntu-zfs"
    then
        step "Adding ZFS Repo: "
            try add-apt-repository -y ppa:zfs-native/stable
            try apt-get update
        next

        step "Installing ubuntu-zfs (this takes a while to compile): "
            try apt-get install -y ubuntu-zfs
        next
    fi

    if ! is_mounted "$zpool_name"
    then
        step "Creating $zpool_name zpool: "
            try zpool create -f $zpool_name mirror sdb sdc mirror sdd sde
            try zfs set compression=lz4 $zpool_name
            try zfs set atime=off $zpool_name
            try zfs set checksum=fletcher4 $zpool_name
        next

        zpool_created=$(zpool status | grep "$zpool_name" | grep ONLINE)

        if [ ! zpool_created ]; then
            echo_failure "Unable to create zpool; aborting provisioning process"
        fi
    fi

    if [ ! -d "/$zpool_name/postgresql" ]; then
        step "Move postgresql directory to /$zpool_name: "
            try service postgresql stop
            try cp /etc/postgresql/9.4/main/postgresql.conf "/etc/postgresql/9.4/main/postgresql.$provision_ts.conf"
            try cp -r /var/lib/postgresql "/$zpool_name"
            try chown -R postgres:postgres "/$zpool_name"
            try wget https://gist.githubusercontent.com/jmealo/3baa5990825a581b3007/raw/5ad9d120fc214eb038b3bf8e9b6da44e05f53efd/postgresql.conf -O /etc/postgresql/9.4/main/postgresql.conf
            try cp /etc/postgresql/9.4/main/pg_hba.conf "/etc/postgresql/9.4/main/pg_hba.conf"
            try wget https://gist.githubusercontent.com/jmealo/318ac0865382bd0f2cdc/raw/4d133a1118395d871abb20f5ef4bd5c5b9530f6f/pg_hba.conf -O /etc/postgresql/9.4/main/pg_hba.conf
            try service postgresql start
        next
    fi

    if [ ! -e "/usr/local/bin/arc_summary.py" ]; then
        step "Installing arc_summary script: "
            try wget https://raw.githubusercontent.com/tiberiusteng/tools/master/arc_summary.py -O /usr/local/bin/arc_summary.py
            try chmod +x /usr/local/bin/arc_summary.py
        next
    fi
else
    # TODO: check if we've already written the configuration file so we don't overwrite changes
    step "Optimizing PostgreSQL configuration"
        try service stop postgresql
        try cp /etc/postgresql/9.4/main/postgresql.conf "/etc/postgresql/9.4/main/postgresql.$provision_ts.conf"
        try wget https://gist.githubusercontent.com/jmealo/7eaa4a8c800f1907e683/raw/1d5477078222755683ae6e88cd4df72ea1a80af0/postgresql.conf -O /etc/postgresql/9.4/main/postgresql.conf
        try cp /etc/postgresql/9.4/main/pg_hba.conf "/etc/postgresql/9.4/main/pg_hba.conf"
        try wget https://gist.githubusercontent.com/jmealo/318ac0865382bd0f2cdc/raw/4d133a1118395d871abb20f5ef4bd5c5b9530f6f/pg_hba.conf -O /etc/postgresql/9.4/main/pg_hba.conf
        try service postgresql start
    next
fi

if ! command_exists "pgxn"
then
    step "Installing PGXN: "
        try easy_install pgxnclient
    next
fi

if ! is_installed "libv8-dev"
then
    step "Installing development dependencies for postgres extensions: "
        try apt-get install -y libyajl-dev libmysqld-dev protobuf-c-compiler libprotobuf-c0-dev libv8-dev
    next
fi

step "Installing postgresql extensions using PGXN: "
    try pgxn_install "mysql_fdw"
    try pgxn_install "json_fdw"
    try pgxn_install "cstore_fdw"
    try pgxn_install "quantile"
    try pgxn_install "trimmed_aggregates"
    try pgxn_install "weighted_mean"
    try pgxn_install "jsonbx"
    try pgxn_install "plv8"
    try pgxn_install "pg_partman" "pg_partman_bgw"
    try pgxn_install "cyanaudit" "cyanaudit" "testing"
    try pgxn_install "temporal_tables" "temporal_tables" "testing"
next

if ! pg_extension_exists "redis_fdw"
then
    step "Installing redis-fdw manually because the PGXN version doesn't install: "
        try mkdir "$provision_ts"
        try cd "$provision_ts"
        try wget --quiet https://github.com/pg-redis-fdw/redis_fdw/archive/REL9_4_STABLE.zip
        try wget --quiet https://github.com/redis/hiredis/archive/master.zip
        try unzip REL9_4_STABLE.zip
        try unzip master.zip
        try mv hiredis-master redis_fdw-REL9_4_STABLE/hiredis
        try cd redis_fdw-REL9_4_STABLE
        try make
        try make install
        try cd ../..
        try rm -rf "$provision_ts"
    next
fi

step "Creating temporary directory for postgrest user"
    try mkdir -p "/tmp/postgres.$provision_ts"
    try chown -R postgres:postgres "/tmp/postgres.$provision_ts"
    try cd "/tmp/postgres.$provision_ts"
next

step "Creating template database with proper encoding: "
    try su postgres -c "psql -c \"UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';\""
    try su postgres -c "psql -c \"DROP DATABASE template1;\""
    try su postgres -c "psql -c \"CREATE DATABASE  template1 with ENCODING = 'UTF-8' LC_CTYPE = 'en_US.utf8' LC_COLLATE = 'en_US.utf8' template = template0;\""
    try su postgres -c "psql -c \"UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';\""
next

step "Creating extensions in PostgreSQL: "
    try sudo -u postgres wget https://gist.githubusercontent.com/jmealo/932470d47ae540399979/raw/bb4966eee3375e7ed993e729b76190694769c0bb/create-extensions.sql
    try sudo -u postgres psql -f create-extensions.sql
next

if sudo -u postgres psql -l | grep '^ spark\b' > /dev/null ; then
    #TODO: this check doesn't work fix it
    step "Creating spark user and database in PostgreSQL"
        try sudo -u postgres psql -c "CREATE USER backpack REPLICATION LOGIN ENCRYPTED PASSWORD 'SparkPoint2015';"
        try sudo -u postgres createdb backpack -O backpack
    next
fi

step "Dropping and re-populating emphemeral tables"
    try wget https://gist.githubusercontent.com/jmealo/0f35303c8c61349efe70/raw/ed686358cf8de48bee03d0c0bc6ef8b12f94d577/standards.tsv -O /tmp/standards.tsv
    try wget https://gist.githubusercontent.com/jmealo/95fe198c54e92fb28da5/raw/f95f22108235630a2721a8c1ddf7822e7372aac4/standards_groups.tsv -O /tmp/standards-groups.tsv
    try wget https://gist.githubusercontent.com/jmealo/3a7c5149a7b6434a34c9/raw/1403c2b72051869c74ebbf5527fa7f4c09e5272a/math_edges.tsv -O /tmp/math_edges.tsv
    try wget https://gist.githubusercontent.com/jmealo/60c9e7623b5868f05b74/raw/01d94789cad52e2bbdb01116579d819681171ed1/provision.sql
    try chown -R postgres:postgres /tmp/*.tsv
    try sudo -u postgres psql spark -f provision.sql
    try sudo -u postgres psql spark -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO spark;"
next

if ! command_exists "pgloader"
then
    step "Installing pgloader"
        try apt-get install -y sbcl unzip libsqlite3-dev make curl gawk freetds-dev libzip-dev
        try wget http://pgloader.io/files/pgloader_3.2.0+dfsg-1_amd64.deb
        try dpkg -i pgloader_3.2.0+dfsg-1_amd64.deb
        try rm pgloader_3.2.0+dfsg-1_amd64.deb
    next
fi

if ! command_exists "postgrest"
then
    step "Installing postgrest"
        try wget https://github.com/begriffs/postgrest/releases/download/v0.2.10.0/postgrest-0.2.10.0-linux.tar.xz
        try tar -xJf postgrest-0.2.10.0-linux.tar.xz -C /usr/local/bin
        try ln -s /usr/local/bin/postgrest-0.2.10.0 /usr/local/bin/postgrest
        try chmod +x /usr/local/bin/postgrest-0.2.10.0
        try useradd -r -s /bin/false postgrest
        try wget https://raw.githubusercontent.com/begriffs/postgrest/master/debian/postgrest.init.d -O /etc/init.d/postgrest
        try chmod +x /etc/init.d/postgrest
        try mkdir -p /var/log/postgrest
        try touch /var/log/postgrest/postgrest.log
        try chown -R postgrest:postgrest /var/log/postgrest
        try mkdir -p /etc/defaults/
        try wget https://gist.githubusercontent.com/jmealo/1cc35550ac015f9e503f/raw/62e9d29fabd6201df8cfe6346771db81cd947026/postgrest -O /etc/default/postgrest
        try wget https://raw.githubusercontent.com/begriffs/postgrest/master/debian/postgrest-wrapper -O /usr/local/bin/postgrest-wrapper
        try chmod +x /usr/local/bin/postgrest-wrapper
        try update-rc.d postgrest defaults
        try rm postgrest-0.2.10.0-linux.tar.xz
        try service postgrest start
    next
fi

step "Cleaning up temporary directory for postgrest user"
    try rm -rf "/tmp/postgres.$provision_ts"
next

if [ ! -d "/opt/phppgadmin" ]; then
  step "Installing phppgadmin"
        try cd /opt
        try git clone https://github.com/phppgadmin/phppgadmin.git
        try apt-get -y install nginx php5-fpm php5-pgsql
        try $(perl -0777 -pe "s/\$conf\['servers'\]\[0\]\['host'\] = '';/\$conf\['servers'\]\[0\]\['host'\] = 'localhost';/" /opt/phppgadmin/conf/config.inc.php-dist > /opt/phppgadmin/conf/config.inc.php)
        try chown -R www-data:www-data /opt/phppgadmin
        try rm /etc/nginx/sites-enabled/default
        try wget https://gist.githubusercontent.com/jmealo/c2fc83a8b5d84bc4297e/raw/75a0e49755794e4e004399aad7b21160b15914e6/phppgadmin -o /etc/nginx/sites-available/phppgadmin
        try ln -s /etc/nginx/sites-available/phppgadmin /etc/nginx/sites-enabled/
        try service nginx reload
        try sudo -u postgres psql -c "CREATE USER developer SUPERUSER REPLICATION LOGIN ENCRYPTED PASSWORD 'SparkPoint2015';"
  next
fi

echo
echo "Provisioning complete, returning to: $provision_dir"
cd "$provision_dir"
echo
exit 0
