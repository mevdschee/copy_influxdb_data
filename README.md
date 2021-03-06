# Copy InfluxDB data

When an incident has happened, or a specific test has been run on an infrastructure and your system is monitored using Collectd/InfluxDB/Grafana, you may want to mark the time segment for further investigation (to avoid automatic removal due to retention rules). This script allows you to do this. 

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
           Execute as if it was run at this time, default: [now]
      --influx 'arguments'
           Arguments for the influx command line tool.
           
Let's say that you have a single database (named 'collectd') with a signle retention policy (named 'collectd') on an InfluxDB instance. If you started an interesting event 2 hours ago and finished just now and want to save that as "test_run_1" you do:

    $ ./copy_influxdb_data.sh --dst-db test_run_1 --from -2h
    
In Grafana you can now easily switch between the databases by changing the database of the (named) InfluxDB datasource.

	$ ./copy_influxdb_data.sh --dst-db test_run_1 --from -2h
	Source: collectd.collectd
	Destination: test_run_1.collectd
	From time: -2h
	Until time: 0s
	Progress:
	  - contextswitch_value: 227 records
	  - cpu_value: 2728 records
	  - df_value: 5520 records
	  - disk_io_time: 221 records
	  - disk_read: 884 records
	  - disk_value: 148 records
	  - disk_weighted_io_time: 221 records
	  - disk_write: 884 records
	  - interface_rx: 908 records
	  - interface_tx: 908 records
	  - irq_value: 8393 records
	  - load_longterm: 227 records
	  - load_midterm: 227 records
	  - load_shortterm: 227 records
	  - memory_value: 1362 records
	  - mysql_value: 12461 records
	  - processes_value: 1621 records
	  - swap_value: 1130 records
	  - tcpconns_value: 2473 records
	  - uptime_value: 223 records
	Done!

As you see the copy has been succeeded.
