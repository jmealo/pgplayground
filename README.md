# pgplayground PostgreSQL with all the fixin's!

## WIP - documentation pending

The provided ``scripts/provision.sh`` script and ``Vagrantfile`` will get you up and running with PostgreSQL 9.4 on Ubuntu 14.04.

You can run ``scripts/provision.sh`` without Vagrant.

### ZFS
If you provision using Vagrant, your VM will have a zpool named tank with LZ4 compression enabled and atime off. PostgeSQL's data files will be put here.

### Included goodies:
1. phppgadmin on port 8080 (db: spark, username: developer, password; SparkPoint2015)
2. [postgrest](https://github.com/begriffs/postgrest) running as a service on port 3000, pointed at db: spark
3. PGXN client
4. pgloader
5. plv8
6. mysql_fdw
7. json_fdw
8. cstore_fdw
9. redis_Fdw
10. quantile
11. trimmed_aggregates
12. weighted_mean
13. jsonbx
14. pg_partman
15. cyanaudit
16. temporal_tables
17. arc_summary (for ZFS)
