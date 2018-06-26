#!/bin/bash
if [[ $# -lt 1 ]];then
  echo "Usage: $(basename $0) database_name"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

dbName=$1


printf "\nRunning the verify edits scrips - Please check spaces page for more information. Copyright Armin & Bogdan\n"


printf "\nApplying initial steps and deleting previous cache tables...\n"
psql -q -U postgres -d $dbName -f $DIR/initial_steps.sql

printf "\nRunning algoritm for deleted features...\n"
psql -q -U postgres -d $dbName -f $DIR/deleted_map_features.sql

printf "\nRunning algoritm for modified...\n"
psql -q -U postgres -d $dbName -f $DIR/modified_map_features.sql


printf "\nScript finished with succes. Check DB for the deleted_final / modified_final table for your MapFeature. Use PostGIS to export it.\n"
