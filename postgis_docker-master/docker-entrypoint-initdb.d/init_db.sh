#!/bin/bash
set -e

export PGUSER="$POSTGRES_USER"

echo "Initializing OSM database schema"
/usr/local/bin/psql -v ON_ERROR_STOP=1 --dbname "osmworld" -f /input/static/database_init.sql

echo "Parallel OSM schema loading"
find /input/*/*/sql/ -type f -name "*.sql" | sort | parallel psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "osmworld" -f {}

echo "Parallel OSM data loading"
for country_dir in /input/*/*_loc_ways; do
    for category in nodes ways relations multipolygon; do
        dir="$country_dir/$category"
        table="osm_$category"

        if [ -d "$dir" ]; then
            echo "Importing $category data from $dir into $table"
            find "$dir" -type f -name "*.tsv" | sort | parallel psql --username "$POSTGRES_USER" --dbname "osmworld" -c "\copy $table FROM '{}'"
        fi
    done
done

echo "Finalizing OSM database"
/usr/local/bin/psql -v ON_ERROR_STOP=1 --dbname "osmworld" -f /input/static/database_after_init.sql

echo "OSM database initialization complete!"
