#!/bin/bash

if [[ whoami -ne "root" ]]; then
    echo "This script should not be run using sudo or as the root user"
    exit 1
fi

echo_failure() {
  # echo first argument in red
  printf "\e[31m ✘ ${1}"
  # reset colours back to normal
  echo -e "\e[0m"
}

echo_success() {
  # echo first argument in green
  printf "\e[32m ✔ ${1}"
  # reset colours back to normal
  echo -e "\e[0m"
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

pgxn_install () {
    local file=$1
    local file=${2:-$file}

    if [ ! -e "/usr/lib/postgresql/9.4/lib/$file.so" ] && [ ! -e "/usr/share/postgresql/9.4/extension/$file.control" ]; then
        if [ -z "$3" ]; then
                pgxn install --yes $1
            else
                pgxn install --yes --$3 $1
            fi
    else
        return 0
    fi
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

if ! is_installed "postgresql-plperl-9.4"
then
    step "Installing PostgreSQL: "
        try wget -O - https://gist.githubusercontent.com/jmealo/0f1e2c9c4befe2b9eeb2/raw/1389e9d3e7327ef0a1cd26c9d1f4d479dfed18a3/apt.postgresql.org.sh | bash
        try apt-get install -y postgresql postgresql-contrib libpq-dev postgresql-server-dev-9.4 postgresql-plperl-9.4
    next
fi

if ! is_installed "ubuntu-zfs"
then
    step "Adding ZFS Repo: "
        try add-apt-repository -y ppa:zfs-native/stable
        try apt-get update
    next

    step "Installing ubuntu-zfs (this takes a while to compile): "
        try apt-get install ubuntu-zfs
    next
fi

zpool_created=$(zpool status | grep tank | grep ONLINE)

if [ ! zpool_created ]; then
    step "Creating tank zpool: "
        try zpool create -f tank mirror sdb sdc mirror sdd sde
        try zfs set compression=lz4 tank
        try zfs set atime=off tank
    next
fi

if [ ! -d "/tank" ]; then
# TODO: we should run initdb and specify the output directory instead of moving it
    step "Move postgresql directory to /tank: "
        try service postgresql stop
        try cp -r /var/lib/postgresql/9.4/main /tank
        try ln -s /tank /var/lib/postgresql/9.4/main
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
    try pgxn_install "pg_partman" "pg_partman_bgw"
    try pgxn_install "cyanaudit" "cyanaudit" "testing"
    try pgxn_install "temporal_tables" "temporal_tables" "testing"
next

# TODO: redis-fdw didn't compile even with libhiredis-dev installed (https://gist.github.com/jmealo/a9271c47a08f783cb9bc)

step "Creating template database with proper encoding: "
    try su postgres -c "psql -c \"UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';\""
    try su postgres -c "psql -c \"DROP DATABASE template1;\""
    try su postgres -c "psql -c \"CREATE DATABASE  template1 with ENCODING = 'UTF-8' LC_CTYPE = 'en_US.utf8' LC_COLLATE = 'en_US.utf8' template = template0;\""
    try su postgres -c "psql -c \"UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';\""
    try su postgres -c "psql -f create-extensions.sql"
next

echo
echo "Provisioning complete"
echo
exit 0