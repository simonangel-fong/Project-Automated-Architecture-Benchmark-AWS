#!/bin/bash

# stop if error
set -euo pipefail

DIR_SCRIPT="/app/script"

echo
echo "##################################################"
echo "Dev logging"
echo "Init DB: starting"
echo "DIR_SCRIPT: $DIR_SCRIPT"
echo "PGHOST: $PGHOST  PGPORT: ${PGPORT:-5432}  PGDATABASE: ${PGDATABASE:-postgres}"
echo "##################################################"
echo

# check directory exists
if [ ! -d "$DIR_SCRIPT" ]; then
    echo "Error: Directory '$DIR_SCRIPT' not found."
    exit 1
fi

# Wait for PostgreSQL to be ready
echo
echo "Waiting for PostgreSQL to become ready..."
until pg_isready -h "$PGHOST" -p "${PGPORT:-5432}" -U "$PGUSER" -d "${PGDATABASE:-postgres}" >/dev/null 2>&1; do
    echo "Postgres is not ready yet. Retrying in 2s..."
    sleep 2
done
echo "PostgreSQL is ready!"

# Run SQL files
shopt -s nullglob
SQL_FILES=("$DIR_SCRIPT"/*.sql)

# check sql file exists
if [ ${#SQL_FILES[@]} -eq 0 ]; then
    echo "No .sql files found in $DIR_SCRIPT. Nothing to do."
    exit 0
fi

for file in "${SQL_FILES[@]}"; do
    echo
    echo "##################################################"
    echo "Executing: $file"
    echo "##################################################"
    echo

    # -v ON_ERROR_STOP=1 -> stop on first error
    psql \
        "postgresql://$PGUSER:$PGPASSWORD@$PGHOST:${PGPORT:-5432}/${PGDATABASE:-postgres}" \
        -v ON_ERROR_STOP=1 \
        -f "$file"
done

echo
echo "##################################################"
echo "Init DB: all scripts executed successfully."
echo "##################################################"
echo
