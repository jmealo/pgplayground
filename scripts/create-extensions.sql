-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements SCHEMA pg_catalog;
-- TODO: This tries to write to a system table and fails; let's review the best way to turn pg_stat_statements on/off

CREATE EXTENSION IF NOT EXISTS plv8 SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS plls SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS plcoffee SCHEMA pg_catalog;

CREATE EXTENSION IF NOT EXISTS mysql_fdw SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS json_fdw SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS cstore_fdw SCHEMA pg_catalog;

CREATE EXTENSION IF NOT EXISTS quantile SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS trimmed_aggregates SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS weighted_mean SCHEMA pg_catalog;

CREATE EXTENSION IF NOT EXISTS temporal_tables SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS jsonbx SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS hstore SCHEMA pg_catalog;

CREATE EXTENSION IF NOT EXISTS plperl SCHEMA pg_catalog;
CREATE SCHEMA IF NOT EXISTS cyanaudit;
CREATE EXTENSION IF NOT EXISTS cyanaudit SCHEMA cyanaudit;
