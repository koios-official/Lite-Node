#!/bin/bash

# su - postgres -c 'pg_isready'

[[ $(( $(date +%s) - $(date --date="$(psql -qt -d ${POSTGRES_DB} -U ${POSTGRES_USER} -c 'select time from block order by id desc limit 1;')" +%s) )) -lt 3600 ]] || return 1
