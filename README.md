# Copy InfluxDB data

When an incident has happened, or a specific test has been run on an infrastructure and you want to mark the time segment for 
further investogation, you can use this script. 

It creates a new database with an infinite rentention and copies in all metrics from a specific time range.

    $ ./copy_influxdb_data.sh -h
    Usage of ./copy_influxdb_data.sh:
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
           
If you started an interesting event 2 hours ago and finished it 5 minutes ago and want to save that as "test_run_1" you do:

    $ ./copy_influxdb_data.sh --dst-db test_run_1 --from -2h --until -5m
    
In Grafana you can now easily switch between the databases by changing the database of the (named) InfluxDB datasource.
