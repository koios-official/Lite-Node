#!/bin/bash


#??????????????????????????????

# Description: Check sync until Alonzo hard-fork
check_db_status() {
    container_id=$(docker ps -qf "name=postgress")
    if [[ "$(docker exec -it -u postgres "$container_id" bash -c "psql -qtAX -d ${POSTGRES_DB} -c 'SELECT protocol_major FROM public.param_proposal WHERE protocol_major > 4 ORDER BY protocol_major DESC LIMIT 1'" 2>/dev/null)" == "" ]]; then
      return 1
    fi
    return 0
}

# Description: Setup basic DB requirements
setup_db_basics() {
    local basics_sql_url="${DB_SCRIPTS_URL}/basics.sql"
    
    if ! basics_sql=$(curl -s -f -m "${CURL_TIMEOUT}" "${basics_sql_url}" 2>&1); then
      echo "Failed to get basic db setup SQL from ${basics_sql_url}"
      return 1
    fi
    echo "Adding grest schema if missing and granting usage for web_anon..."
    if ! output=$(psql "${PGDATABASE}" -v "ON_ERROR_STOP=1" -q <<< "${basics_sql}" 2>&1); then
      echo "${output}"
      return 1
    fi
    echo "Basic DB setup successful."
}



# Description : Deployment list (will only proceed if sync status check passes):
  #             : 1) grest DB basics - schema, web_anon user, basic grest-specific tables
  #             : 2) RPC endpoints - with SQL sourced from files/grest/rpc/**.sql
  #             : 3) Cached tables setup - with SQL sourced from files/grest/rpc/cached_tables/*.sql
  #             :    This includes table structure setup and caching existing data (for most tables).
  #             :    Some heavy cache tables are intentionally populated post-setup (point 4) to avoid long setup runtimes. 
  #             : 4) Cron jobs - deploy cron entries to /etc/cron.d/ from files/grest/cron/jobs/*.sh
  #             :    Used for updating cached tables data.
deploy_query_updates() {
    printf "\n(Re)Deploying Postgres RPCs/views/schedule...\n"
    check_db_status
    if [[ $? -eq 1 ]]; then
      err_exit "Please wait for Cardano DBSync to populate PostgreSQL DB at least until Alonzo fork, and then re-run this setup script with the -q flag."
    fi

    printf "\n  Downloading DBSync RPC functions from Guild Operators GitHub store..."
    if ! rpc_file_list=$(curl -s -f -m ${CURL_TIMEOUT} https://api.github.com/repos/${G_ACCOUNT}/koios-artifacts/contents/files/grest/rpc?ref=${SGVERSION} 2>&1); then
      err_exit "${rpc_file_list}"
    fi
    printf "\n  (Re)Deploying GRest objects to DBSync..."
    populate_genesis_table
    for row in $(jq -r '.[] | @base64' <<<${rpc_file_list}); do
      if [[ $(jqDecode '.type' "${row}") = 'dir' ]] && [[ $(jqDecode '.name' "${row}") != 'db-scripts' ]]; then
        printf "\n    Downloading pSQL executions from subdir $(jqDecode '.name' "${row}")"
        if ! rpc_file_list_subdir=$(curl -s -m ${CURL_TIMEOUT} "https://api.github.com/repos/${G_ACCOUNT}/koios-artifacts/contents/files/grest/rpc/$(jqDecode '.name' "${row}")?ref=${SGVERSION}"); then
          printf "\n      \e[31mERROR\e[0m: ${rpc_file_list_subdir}" && continue
        fi
        for row2 in $(jq -r '.[] | @base64' <<<${rpc_file_list_subdir}); do
          deploy_rpc ${row2}
        done
      else
        deploy_rpc ${row}
      fi
    done
    setup_cron_jobs
    printf "\n  All RPC functions successfully added to DBSync! For detailed query specs and examples, visit ${API_DOCS_URL}!\n"
    printf "\nRestarting PostgREST to clear schema cache..\n"
    sudo systemctl restart ${CNODE_VNAME}-postgrest.service && printf "\nDone!!\n"
}



#???????????????????????????????????
