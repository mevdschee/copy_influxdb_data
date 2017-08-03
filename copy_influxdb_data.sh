#!/usr/bin/env bash
set -o errexit -o noclobber -o nounset -o pipefail
params="$(getopt -o h -l influx:,src-db:,src-rp:,dst-db:,dst-rp:,from:,until,from-abs:,until-abs: --name "$0" -- "$@")"
eval set -- "$params"

SRC_DB=
SRC_RP=
DST_DB=
DST_RP=
FROM=
UNTIL=
NOW=
INFLUX_ARGS=

while true
do
    case "$1" in
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
        --now)
            NOW=$2
            shift 2
            ;;
        --influx)
            INFLUX_ARGS=$2
            shift 2
            ;;
        -h) cat << EOF
Usage of $0:
  --src-db 'database name'
       Name of the database to copy, default: [first-db]
  --src-rp 'rentention profile'
       Rentention profile to copy, default: [first-rp]
  --dst-db 'database name'
       Database to copy into, default: [src-db][number]
  --from 'relative time'
       Relative time from when to copy, default: '-1h'
  --until 'relative time until when to copy'
       Relative time until when to copy, default: '0s'
  --now 'current absolute time'
       To copy data at an arbitrary time, default: [now]
  --influx 'arguments'
       Arguments for the influx command line tool.
EOF
            shift
            exit 0
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

# default name of source database to first profile
if [ "$SRC_DB" = "" ]; then
    SRC_DB=$(influx $INFLUX_ARGS -execute "show databases" -format csv | tail -n +2 | head -n 1 | cut -d, -f2)
    if [ "$SRC_DB" = "_internal" ]; then
        SRC_DB=$(influx $INFLUX_ARGS -execute "show databases" -format csv | tail -n +3 | head -n 1 | cut -d, -f2)
    fi
fi

# default source rentention profile to first profile
if [ "$SRC_RP" = "" ]; then
    SRC_RP=$(influx $INFLUX_ARGS -database $SRC_DB -execute "show retention policies" -format csv | tail -n +2 | head -n 1 | cut -d, -f1)
fi

# default name of database copy to "{source database name}{database number}"
if [ "$DST_DB" = "" ]; then
    NUMBER=$(influx $INFLUX_ARGS -execute "show databases" -format csv | tail -n +2 | wc -l)
    DST_DB="${SRC_DB}${NUMBER}"
fi

# default name of rentention profile on copy to it's source
if [ "$DST_RP" = "" ]; then
    DST_RP=$SRC_RP
fi

# default "until" time to now
if [ "$NOW" = "" ]; then
    NOW=$(date +%s)s
fi

# default "from" time to one hour ago
if [ "$FROM" = "" ]; then
    FROM="-1h"
fi

# default "until" time to now
if [ "$UNTIL" = "" ]; then
    UNTIL="0s"
fi

echo Source:      $SRC_DB.$SRC_RP
echo Destination: $DST_DB.$DST_RP
echo From time:   $FROM
echo Until time:  $UNTIL
echo Progress:
influx $INFLUX_ARGS -execute "CREATE DATABASE $DST_DB WITH DURATION inf REPLICATION 1 NAME $DST_RP"
for MEASUREMENT in $(influx $INFLUX_ARGS -database $SRC_DB -execute "show measurements" -format csv | tail -n +2 | cut -d, -f2); do
    echo -n "  - $MEASUREMENT: "
    NUMBER=$(influx $INFLUX_ARGS -execute "SELECT * INTO $DST_DB.$DST_RP.$MEASUREMENT FROM $SRC_DB.$SRC_RP.$MEASUREMENT WHERE time > $NOW + $FROM and time <= $NOW + $UNTIL GROUP BY *" -format csv | tail -n +2 | head -n 1 | cut -d, -f3)
    echo "$NUMBER records"
done
echo Done!
