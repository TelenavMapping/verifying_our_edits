DROP TABLE IF EXISTS verify.deleted_final_tr;
DROP TABLE IF EXISTS verify.deleted_final_road_geometry;
DROP TABLE IF EXISTS verify.modified_road_geometry;
DROP TABLE IF EXISTS verify.navigable_verify;
DROP TABLE IF EXISTS public.navigable_current;
DROP TABLE IF EXISTS verify.restrictions_verify;
DROP TABLE IF EXISTS public.restrictions_current;
drop table if exists verify.modified_turn_restrictions; 
drop table if exists verify.modified_singpost;
drop table if exists verify.deleted_name_tag;

---drop table if exists verify.modified_signpost;

--- create specific navigable_verify

CREATE TABLE verify.navigable_verify AS (
SELECT id, tags, tags->'highway' fc, linestring
FROM verify.ways
WHERE tags->'highway' in ( 'motorway', 'motorway_link','trunk', 'trunk_link', 'primary', 'primary_link' , 'secondary', 'secondary_link', 'tertiary',
 'tertiary_link', 'residential', 'unclassified', 'service', 'construction', 'proposed')
);

---update FC information. FC level are not official or standard

UPDATE  verify.navigable_verify SET fc='1' WHERE fc LIKE'%motorway%';
UPDATE  verify.navigable_verify SET fc='2' WHERE fc LIKE'%primary%' OR fc like'%trunk%';
UPDATE  verify.navigable_verify SET fc='3' WHERE fc like'%secondary%';
UPDATE  verify.navigable_verify SET fc='4' WHERE fc like'%tertiary%';
UPDATE  verify.navigable_verify SET fc='5' WHERE fc LIKE'%residential%'  OR fc like'%unclassified%' OR tags->'route'='ferry' OR fc like'%living_street%' OR fc like'%service%' OR fc like'%track%' or fc LIKE'%road%';

--- create specific navigable_current

CREATE TABLE public.navigable_current AS (
SELECT id, tags, tags->'highway' fc, linestring
FROM public.ways
WHERE tags->'highway' in ( 'motorway', 'motorway_link','trunk', 'trunk_link', 'primary', 'primary_link' , 'secondary', 'secondary_link', 'tertiary',
 'tertiary_link', 'residential', 'unclassified', 'service', 'construction', 'proposed')
);

---update FC information. FC level are not official or standard

UPDATE  public.navigable_current SET fc='1' WHERE fc LIKE'%motorway%';
UPDATE  public.navigable_current SET fc='2' WHERE fc LIKE'%primary%' OR fc like'%trunk%';
UPDATE  public.navigable_current SET fc='3' WHERE fc like'%secondary%';
UPDATE  public.navigable_current SET fc='4' WHERE fc like'%tertiary%';
UPDATE  public.navigable_current SET fc='5' WHERE fc LIKE'%residential%'  OR fc like'%unclassified%' OR tags->'route'='ferry' OR fc like'%living_street%' OR fc like'%service%' OR fc like'%track%' or fc LIKE'%road%';


---create signpost tables

CREATE TABLE verify.node_rest AS (
SELECT node_id FROM verify.way_nodes
WHERE way_id in (SELECT id FROM verify.ways WHERE tags->'highway' in ('primary', 'secondary', 'tertiary', 'residential', 'unclassified', 'service')));
    
CREATE TABLE verify.way_motorway AS (
SELECT id, tags, linestring FROM verify.navigable_verify
WHERE( tags->'highway'='motorway_link' or tags->'highway'='trunk_link')
);
    
CREATE TABLE verify.signpost_tag2 AS (
SELECT id, tags, linestring FROM verify.way_nodes, verify.way_motorway
WHERE node_id in ( SELECT node_id FROM verify.node_rest)
and way_id=way_motorway.id
and sequence_id ='0'
GROUP BY node_id, id, tags, linestring);
DROP TABLE verify.node_rest, verify.way_motorway;
  
--off ramps
CREATE TABLE verify.off_ramp AS(
SELECT distinct way.id way_id, way.tags way_tags, node.tags node_tags, way.linestring
FROM (SELECT id, tags FROM nodes WHERE tags->'highway'='motorway_junction')node,
     (SELECT id, tags, linestring FROM verify.navigable_verify  WHERE tags->'highway'like'%link') way, verify.way_nodes
WHERE way.id=way_nodes.way_id and node.id=way_nodes.node_id and sequence_id ='0');
  
CREATE TABLE verify.signpost_tag AS (
SELECT way_id id, way_tags tags, linestring
FROM verify.off_ramp
WHERE  (way_tags?'destination' or way_tags?'destination:ref' or way_tags ?'destination:ref:to' or way_tags ?'destination:street')
 and (node_tags?'exit_to' or node_tags?'exit_to:left' or node_tags?'exit_to:right' or node_tags?'ref' or node_tags?'ref:left' or node_tags?'ref:right' or node_tags?'noref'));
DROP TABLE verify.off_ramp;
  
-- signpost
CREATE TABLE verify.signpost_all_verify AS (
SELECT *
FROM verify.signpost_tag2
WHERE (tags?'destination' or tags?'destination:ref' or tags ?'destination:ref:to' or tags ?'destination:street')
UNION
SELECT *
FROM verify.signpost_tag
WHERE (tags?'destination' or tags?'destination:ref' or tags ?'destination:ref:to' or tags ?'destination:street'))
