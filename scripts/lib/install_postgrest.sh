#!/bin/bash
# Description: Drop all triggers and recreate grest schema
recreate_grest_schema() {
    local reset_sql_url="${DB_SCRIPTS_URL}/reset_grest.sql"
    
    if ! reset_sql=$(curl -s -f -m "${CURL_TIMEOUT}" "${reset_sql_url}" 2>&1); then
      echo "Failed to get reset grest SQL from ${reset_sql_url}."
      return 1
    fi
    echo "Resetting grest schema..."
    if ! output=$(psql "${PGDATABASE}" -v "ON_ERROR_STOP=1" -q <<< "${reset_sql}" 2>&1); then
      echo "${output}"
      return 1
    fi
    echo "Grest schema reset successful."
}

# Description: Fully reset the grest node from the database POV
reset_grest() {
    local tr_dir="${HOME}/git/${CNODE_VNAME}-token-registry"
    [[ -d "${tr_dir}" ]] && rm -rf "${tr_dir}"
    recreate_grest_schema
}

# Description : Update the setup-grest.sh version used in the database.
  update_grest_version() {
    koios_release_commit="$(curl -s https://api.github.com/repos/${G_ACCOUNT}/koios-artifacts/commits/${SGVERSION} | jq -r '.sha')"
    [[ -z ${koios_release_commit} ]] && koios_release_commit="null"
    [[ "${RESET_GREST}" == "Y" ]] && artifacts=['reset',"${koios_release_commit}"] || artifacts=["${koios_release_commit}"]

    ! output=$(/usr/bin/psql -U $POSTGRES_USER -d $POSTGRES_DB -qbt -c "SELECT GREST.update_control_table(
        'version',
        '${SGVERSION}',
        '${artifacts}'
      );" 2>&1 1>/dev/null) && err_exit "${output}"
  }

