#!/usr/bin/env bash
set -o errexit -o noclobber -o nounset -o pipefail
params="$(getopt -o h -l influx:,src-db:,src-rp:,dst-db:,dst-rp:,from:,until: --name "$0" -- "$@")"
eval set -- "$params"

INFLUX_ARGS=
SRC_DB=
SRC_RP=
DST_DB=
DST_RP=
FROM=
UNTIL=

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

# default name of source database to first profile
if [ "$SRC_DB" = "" ]; then
    SRC_DB=$(influx $INFLUX_ARGS -execute "show databases" -format csv | tail -n +2 | head -n 1 | cut -d, -f2)
    if [ "$SRC_DB" = "_internal" ]; then
        SRC_DB=$(influx $INFLUX_ARGS -execute "show databases" -format csv | tail -n +3 | head -n 1 | cut -d, -f2)
    fi
fi

# default source replication profile to last profile
if [ "$SRC_RP" = "" ]; then
    SRC_RP=$(influx $INFLUX_ARGS -database $SRC_DB -execute "show retention policies" -format csv | tail -n +2 | head -n 1 | cut -d, -f1)
fi

# default name of database copy to "{source database name}{database number}"
if [ "$DST_DB" = "" ]; then
    NUMBER=$(influx $INFLUX_ARGS -execute "show databases" -format csv | tail -n +2 | wc -l)
    DST_DB="${SRC_DB}${NUMBER}"
fi

# default name of replication profile on copy to it's source
if [ "$DST_RP" = "" ]; then
    DST_RP=$SRC_RP
fi

# default "from" time to one hour ago
if [ "$FROM" = "" ]; then
    FROM="$TIME - 1h"
fi

# default "until" time to now
if [ "$UNTIL" = "" ]; then
    UNTIL=$TIME
fi

echo Copying InfluxDB data
echo Timestamp:   $TIME
echo Source:      $SRC_DB.$SRC_RP
echo Destination: $DST_DB.$DST_RP
echo From time:   $FROM
echo Until time:  $UNTIL
echo
influx $INFLUX_ARGS -execute "CREATE DATABASE $DST_DB WITH DURATION inf REPLICATION 1 NAME $DST_RP"
for MEASUREMENT in $(influx $INFLUX_ARGS -database $SRC_DB -execute "show measurements" | tail -n +4); do
    echo -n "$MEASUREMENT "
    NUMBER=$(influx $INFLUX_ARGS -execute "SELECT * INTO $DST_DB.$DST_RP.$MEASUREMENT FROM $SRC_DB.$SRC_RP.$MEASUREMENT WHERE time > $FROM and time <= $UNTIL GROUP BY *" -format csv | tail -n +2 | head -n 1 | cut -d, -f3)
    echo $NUMBER
done
echo
echo Done!
