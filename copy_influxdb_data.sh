#!/usr/bin/env bash
set -o errexit -o noclobber -o nounset -o pipefail
params="$(getopt -o h -l influx:,src-db:,src-rp:,dst-db:,dst-rp:,from:,until: --name "$0" -- "$@")"
eval set -- "$params"

while true
do
    case "$1" in
        --influx)
            INFLUX_ARGS=$2
            shift 2
            ;;
        --src-db)
            SRC_DB=$2
            shift 2
            ;;
        --src-rp)
            SRC_RP=$2
            shift 2
            ;;
        --dst-db)
            DST_DB=$2
            shift 2
            ;;
        --dst-rp)
            DST_RP=$2
            shift 2
            ;;
        --from)
            FROM=$2
            shift 2
            ;;
        --until)
            UNTIL=$2
            shift 2
            ;;
        -h) cat << EOF
Usage of $0:
  --influx 'arguments'
       Arguments for the influx command line tool.
  --src-db 'database name'
       Name of the database to copy
  --src-rp 'replication profile'
       Replication profile to copy
  --dst-db 'database name'
       Database to connect to the server.
  --from 'time from when to copy'
       For instance 'now()-1h' copies last hour
  --until 'time until when to copy'
       Leave empty to copy until current time
EOF
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Not implemented: $1" >&2
            exit 1
            ;;
    esac
done

TIME=$(date +%s)s

# default name of source database to "collectd"
if [ $SRC_DB -eq "" ]; then
    echo Assuming "--src-db=collectd"
    SRC_DB=collectd
fi

# default source replication profile to "collectd"
if [ $SRC_RP -eq "" ]; then
    echo Assuming "--src-rp=$SRC_DB"
    SRC_RP=$SRC_DB
fi

# default name of database copy to "{source database name}-{timestamp}"
if [ $DST_DB -eq "" ]; then
    $DST_DB="$SRC_DB-$TIME"
fi

# default name of replication profile on copy to it's source
if [ $DST_RP -eq "" ]; then
    $DST_RP=$SRC_RP
fi

# default "from" time to one hour ago
if [ $FROM -eq "" ]; then
    $FROM="$TIME - 1h"
fi

# default "until" time to now
if [ $UNTIL -eq "" ]; then
    $UNTIL=$TIME
fi

influx -execute "CREATE DATABASE $DST_DB WITH DURATION inf REPLICATION 1 NAME $DST_RP"
for MEASUREMENT in `influx -database $SRC_DB -execute "show measurements" | tail -n +4`; do
    influx $INFLUX_ARGS -execute "SELECT * INTO $DST_DB.$DST_RP.$MEASUREMENT FROM $SRC_DB.$SRC_RP.$MEASUREMENT WHERE time > $FROM and time <= $UNTIL GROUP BY *"
done
