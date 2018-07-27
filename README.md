## Verifying our edits Script
The script allows a user to import two OSM.PBF files to postgreSQL and calculate the differences between them. It divides these differences into two categories :
* Deleted map features
* Modified map features

The output files are in ESRI shapefile format or __geoJSON__.

## Dependencies :
* Unix based OS
* osmosis
* postgreSQL
* postGIS
* pgsql2shp
* ogr2ogr


## How to run it 
Download two OSM.PBF files from a reliable source - we used [Geofabrik extracts](https://osm-internal.download.geofabrik.de/) because of easy implementation of history PBFs extracts. 
Proceed by running the main shell in your terminal and follow the instructions.  

Just run  ``` sh main.sh ```


__Short tutorial__



## Ouput example
**Deleted map features**

<img src="https://imgur.com/2itzdB7.png" width="425"/> <img src="https://imgur.com/ORY38H2.png" width="425"/> 

**Modified map features**
  
<img src="https://imgur.com/p4IuBwh.png" width="425"/> <img src="https://imgur.com/GFJ7jv1.png" width="443"/> 


If you have any questions or feedback contact us at:  
armin.gheorghina@telenav.com  
bogdan.petrea@telenav.com
