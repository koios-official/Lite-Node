#!/bin/bash

CURRTIME=$(date +%s)

[[ $(( $(date +%s) - $(date --date="$(psql -Aqt -h ${POSTGRES_HOST} -c 'select time from block order by id desc limit 1;')" +%s) )) -lt 3600 ]] || exit 1
echo "Block table seems to be on tip or close enough, current time is `date`"

IS_PG_INIT=`psql -h ${POSTGRES_HOST} -Aqb -t -c "select exists(select 1 from information_schema.tables where table_name = 'control_table' and table_schema = '${RPC_SCHEMA}');"`
echo "PG_INIT is initially: $IS_PG_INIT"
if [[ $IS_PG_INIT == "t" ]]; then
  IS_PG_INIT=`psql -h ${POSTGRES_HOST} -Aqb -t -c "select exists(select 1 from ${RPC_SCHEMA}.control_table where key = 'postgres_init_timestamp' and last_value is not null)"`
fi

echo "IS_POSTGRES_INITIALIZED is ${IS_PG_INIT}"

if [[ $IS_PG_INIT == "f" ]]; then
  echo "Commencing PG init"
  /scripts/lib/install_postgres.sh
  psql -h ${POSTGRES_HOST} -qb -c "INSERT INTO ${RPC_SCHEMA}.control_table (key, last_value) VALUES ('postgres_init_timestamp','${CURRTIME}');"
  echo "Done postgres init"
fi



