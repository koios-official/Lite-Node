#!/bin/bash

# Database credentials
# source .env

# Function to list databases, tables, indexes, and keys
list_db_structure() {
    # List all databases
    # databases=$(psql -U $POSTGRES_USER -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
    databases="$POSTGRES_DB"
    
    for db in $databases; do
        echo "Database: $db"
        
        # List all tables in each database
        tables=$(psql -U $POSTGRES_USER -d "$db" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';")
        
        for table in $tables; do
            echo "  Table: $table"

            # List all indexes and keys for each table
            indexes=$(psql -U $POSTGRES_USER -d "$db" -c "SELECT indexname FROM pg_indexes WHERE tablename = '$table';")
            for index in $indexes; do
                echo "    Index: $index"
            done

            # Add similar queries for keys if needed
        done
    done
}

# Run the function
list_db_structure
