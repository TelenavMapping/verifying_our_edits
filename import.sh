echo "Welcome to Verify - (databaSe Creator Osmosis Postgis loadEr)"
echo "Enter the name of the PostgreSQL user account"
read user
echo "$(tput setaf 3) The PostgreSQL user is " $user $(tput sgr 0)
echo "Please enter the database name in this format Country_Code-YYMMDD ( RO-160107 )"
read database
echo "$(tput setaf 3)"the database name is $database $(tput sgr 0)

createdb -O $user $database -U $user
psql -U $user -d $database -c 'CREATE EXTENSION hstore;'
psql -U $user -d $database -c 'CREATE EXTENSION postgis;'
psql -U $user -d $database -c 'CREATE SCHEMA verify;'
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6.sql
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_linestring.sql


echo "Enter the name of the OLD file, without the extension ( example : romania-latest.osm.pbf will be romania-latest  )"
read osmfile
echo "$(tput setaf 3) Enter password for user " $user "( better safe them sorry )" $(tput sgr 0)
read pass

export _JAVA_OPTIONS=-Djava.io.tmpdir=/data1/tmp1
osmosis -v --rbf $osmfile.osm.pbf --wp host=localhost database=$database user=$user password=$pass

echo "Altering the tables into the old schema. Please wait ..."
psql -U $user -d $database -c 'ALTER TABLE nodes SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE relation_members SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE relations SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE users SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE way_nodes SET SCHEMA verify;'
psql -U $user -d $database -c 'ALTER TABLE ways SET SCHEMA verify;'
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6.sql
psql -U $user -d $database -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_linestring.sql

echo "Enter the name of the NEW file, without the extension ( example : romania-latest.osm.pbf will be romania-latest)"
read osmfile2

export _JAVA_OPTIONS=-Djava.io.tmpdir=/data1/tmp1
osmosis -v --rbf $osmfile2.osm.pbf --wp host=localhost database=$database user=$user password=$pass

#psql -U $user -d $database -c 'ALTER SCHEMA public RENAME TO current;'