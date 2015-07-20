#!/bin/bash

if [[ whoami -ne "root" ]]; then
    echo "This script should not be run using sudo or as the root user"
    exit 1
fi

provision_ts=$(date +"%s")
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
        try locale-gen en_US.UTF-8
        try update-locale LANG=en_US.UTF-8
    next
fi

if ! command_exists "add-apt-repository" ] || ! is_installed "git" || ! is_installed "unzip"
then
    step "Installing packages required to install other packages: "
        try apt-get install -y python-software-properties python-setuptools wget curl unzip nano ca-certificates git
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
        try service postgresql start
    next
fi

if [ ! -e "/usr/local/bin/arc_summary.py" ]; then
    step "Installing arc_summary script: "
        try wget https://raw.githubusercontent.com/tiberiusteng/tools/master/arc_summary.py -O /usr/local/bin/arc_summary.py
        try chmod +x /usr/local/bin/arc_summary.py
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

step "Creating template database with proper encoding: "
    try su postgres -c "psql -c \"UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';\""
    try su postgres -c "psql -c \"DROP DATABASE template1;\""
    try su postgres -c "psql -c \"CREATE DATABASE  template1 with ENCODING = 'UTF-8' LC_CTYPE = 'en_US.utf8' LC_COLLATE = 'en_US.utf8' template = template0;\""
    try su postgres -c "psql -c \"UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';\""
next

step "Creating extensions in PostgreSQL: "
    try su postgres -c "psql -f /vagrant/scripts/create-extensions.sql"
next

echo
echo "Provisioning complete"
echo
exit 0
