# Welcome to the 'Verifying our edits' script 
## Import PBF files in postgres using OSMOSIS

echo "Welcome to the Database OSM.PBF loader"
echo "Enter the name of the PostgreSQL user account :"
read user
echo "$(tput setaf 3)Your PostgreSQL user is :" $user $(tput sgr 0)
echo "Enter your database name:"
read database
echo "$(tput setaf 3)"the database name is $database $(tput sgr 0)

#create the database and OSM dependencies 
createdb -O $user $database -U $user
psql -U $user -d $database -c 'CREATE EXTENSION hstore;'
psql -U $user -d $database -c 'CREATE EXTENSION postgis;'
psql -U $user -d $database -c 'CREATE SCHEMA verify;'
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6.sql
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_linestring.sql

#reading old file
echo "Enter the name of the first OSM.PBF file (OLD) without the extension - north-america-latest.osm.pbf will be north-america-latest"
read osmfile
echo "$(tput setaf 3)Enter password for user" $user $(tput sgr 0)
read pass

#import using OSMOSIS into public schema
osmosis -v --rbf $osmfile.osm.pbf --wp host=localhost database=$database user=$user password=$pass

#migrating tables to new schema
echo "Altering the tables to the old DB schema. Please wait ..."
psql -U $user -d $database -c 'ALTER TABLE nodes SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE relation_members SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE relations SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE users SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE way_nodes SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE ways SET SCHEMA verify;'
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6.sql
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_linestring.sql

echo "Enter the name of the second OSM.PBF (NEW) without the extension - north-america-latest.osm.pbf will be north-america-latest"
read osmfile2

#import using OSMOSIS
osmosis -v --rbf $osmfile2.osm.pbf --wp host=localhost database=$database user=$user password=$pass

echo "Import successful. Running the verify_main.sh"

#starting the second part of the script
printf "\nRunning the verify edits script - Please check Github for more information.\n"

#Prerequisites
printf "\nApplying initial steps and deleting previous cache tables...\n"
psql -q -U postgres -d $database -f initial_steps.sql

#deleted features SQL querries
printf "\nRunning algoritm for deleted features. Please wait...\n"
psql -q -U postgres -d $database -f deleted_map_features.sql

#modified features SQL querries 
printf "\nRunning algoritm for modified. Please wait...\n"
psql -q -U postgres -d $database -f modified_map_features.sql

printf "\nExporting output...\n"

#create output folder
mkdir output
cd output

#exporting file using pgsql2shp and converting it to geoJSON format
echo "Enter your host in order to directly export output. You can also manually export using POSTGIS"
read host
echo "$(tput setaf 3)Your host is :" $host $(tput sgr 0)

#export files to path 
pgsql2shp -f "$PWD/deleted_final_road_geometry" -h $host -u mapuser -P 5432 $database verify.deleted_final_road_geometry
pgsql2shp -f "$PWD/deleted_final_tr" -h $host -u mapuser -P 5432 $database verify.deleted_final_tr
pgsql2shp -f "$PWD/deleted_name_tag" -h $host -u mapuser -P 5432 $database verify.deleted_name_tag
pgsql2shp -f "$PWD/modified_singpost" -h $host -u mapuser -P 5432 $database verify.modified_singpost
pgsql2shp -f "$PWD/modified_turn_restrictions" -h $host -u mapuser -P 5432 $database verify.modified_turn_restrictions

#IF EXISTS convert the shapefiles to GeoJSON
if [ -e deleted_final_road_geometry.shp ];
then
	ogr2ogr -f "GeoJSON" deleted_final_road_geometry.json deleted_final_road_geometry.shp
else
	echo "No deleted_final_road_geometry"
fi

if [ -e deleted_final_tr.shp ];
then
	ogr2ogr -f "GeoJSON" deleted_final_tr.json deleted_final_tr.shp
else
	echo "No deleted_final_tr"
fi

if [ -e deleted_name_tag.shp ];
then
	ogr2ogr -f "GeoJSON" deleted_name_tag.json deleted_name_tag.shp
else
	echo "No deleted_name_tag"
fi

if [ -e modified_singpost.shp ];
then
	ogr2ogr -f "GeoJSON" modified_singpost.json modified_singpost.shp
else
	echo "No modified_singpost"
fi

if [ -e modified_turn_restrictions.shp ];
then
	ogr2ogr -f "GeoJSON" modified_turn_restrictions.json modified_turn_restrictions.shp
else
	echo "No modified_turn_restrictions"
fi

printf "\nScript finished successfully. Output files are located here "
echo $PWD

#created by Armin & Bogdan