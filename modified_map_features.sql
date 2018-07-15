---1
create table verify.node_old as (
select distinct(verify.way_nodes.node_id) from verify.way_nodes, verify.navigable_verify where verify.way_nodes.way_id = verify.navigable_verify.id);

---2
create table verify.node_old_geom as (
select verify.node_old.node_id, verify.nodes.geom, ST_X(geom), ST_Y(geom), ST_AsText(geom) from verify.node_old, verify.nodes where verify.node_old.node_id = verify.nodes.id);

create table verify.node_new as (
select distinct(verify.way_nodes.node_id) from verify.way_nodes, public.navigable_current where verify.way_nodes.way_id = public.navigable_current.id);

create table verify.node_new_geom as (
select verify.node_new.node_id, public.nodes.geom, ST_X(geom), ST_Y(geom), ST_AsText(geom) from verify.node_new, public.nodes where verify.node_new.node_id = public.nodes.id);

create table verify.all_nodes as (
select verify.node_old_geom.node_id, verify.node_old_geom.st_x, verify.node_old_geom.st_y, verify.node_new_geom.st_x as st_x_2, verify.node_new_geom.st_y as st_y_2, verify.node_old_geom.geom
from verify.node_old_geom, verify.node_new_geom
where verify.node_old_geom.node_id = verify.node_new_geom.node_id);

create table verify.all_nodes_fc as
(SELECT DISTINCT(verify.all_nodes.node_id),verify.all_nodes.st_x, verify.all_nodes.st_y, verify.all_nodes.st_x_2, verify.all_nodes.st_y_2, verify.all_nodes.geom, verify.way_nodes.way_id
FROM
verify.all_nodes, verify.way_nodes
WHERE
verify.way_nodes.node_id = verify.all_nodes.node_id);


create table verify.node_differences_final as (
SELECT node_id, st_x, st_y, st_x_2, st_y_2, geom, st_x-st_x_2 as diff_x, st_y - st_y_2 as diff_y, way_id,
st_distance(
st_geomfromtext('POINT('||st_x||' '||st_y||')',4326)::geography,
st_geomfromtext('POINT('||st_x_2||' '||st_y_2||')',4326)::geography,true
) as dist,
'Linestring('||st_x||' '||st_y||','||st_x_2||' '||st_y_2||')' as line
-- st_geomfromtext(st_x_2,st_y_2)::geography) dist
FROM verify.all_nodes_fc 
order by dist desc
);

delete from verify.node_differences_final where dist = 0;

CREATE table verify.modified_road_geometry as
(select verify.node_differences_final.*, tags->'highway' fc
FROM verify.node_differences_final, verify.ways
WHERE verify.node_differences_final.way_id = verify.ways.id);

delete from verify.modified_road_geometry WHERE (fc = 'motorway' OR fc = 'motorway_link') AND dist <= 75;
delete from verify.modified_road_geometry WHERE (fc = 'trunk' OR fc = 'trunk_link') AND dist <= 75;
delete from verify.modified_road_geometry WHERE (fc = 'primary' OR fc = 'primary_link') AND dist <= 50;
delete from verify.modified_road_geometry WHERE (fc = 'secondary' OR fc = 'secondary_link') AND dist <= 50;
delete from verify.modified_road_geometry WHERE (fc = 'tertiary' OR fc = 'tertiary_link') AND dist <= 50;
delete from verify.modified_road_geometry WHERE dist <= 30;

ALTER TABLE verify.modified_road_geometry DROP COLUMN geom;
ALTER TABLE verify.modified_road_geometry ALTER COLUMN line TYPE Geometry(LINESTRING, 4326) USING ST_SetSRID(line::Geometry,4326);

drop table if exists verify.node_old;
drop table if exists verify.node_old_geom;
drop table if exists verify.node_new;
drop table if exists verify.node_new_geom;
drop table if exists verify.all_nodes;
drop table if exists verify.all_nodes_fc;
drop table if exists verify.node_differences_final;


--- detect modified TRs based on version

create table verify.turn_restriction_modified as
(select public.restrictions_current.id, public.restrictions_current.version, public.restrictions_current.user_id, public.restrictions_current.tags from verify.restrictions_verify, public.restrictions_current where (public.restrictions_current.id = verify.restrictions_verify.id) 
AND
(verify.restrictions_verify.version != public.restrictions_current.version));


--- match modified TRs with new geometry. join deleted_tr with relation_members to see what relation_id are deleted

create table verify.turn_restriction_modified_members as (
select verify.turn_restriction_modified.id, verify.turn_restriction_modified.version, verify.turn_restriction_modified.user_id, verify.turn_restriction_modified.tags, verify.relation_members.member_id, verify.relation_members.member_role from verify.turn_restriction_modified, verify.relation_members
WHERE verify.turn_restriction_modified.id = verify.relation_members.relation_id);

--- match deleted_tr_members with ways (geometry). Also with nodes - ways1

create table verify.modified_turn_restrictions as
(select verify.turn_restriction_modified_members.id, verify.turn_restriction_modified_members.version, verify.turn_restriction_modified_members.user_id, verify.turn_restriction_modified_members.tags, verify.turn_restriction_modified_members.member_id, verify.turn_restriction_modified_members.member_role, verify.navigable_verify.linestring 
FROM verify.turn_restriction_modified_members, verify.navigable_verify
WHERE verify.turn_restriction_modified_members.member_id = verify.navigable_verify.id);

--- match deleted_tr_members with ways (geometry). Also with nodes - ways2


create table verify.turn_restriction_modified_geom_to_delete as
(select verify.modified_turn_restrictions.id, verify.modified_turn_restrictions.version, verify.modified_turn_restrictions.user_id, verify.modified_turn_restrictions.tags, verify.modified_turn_restrictions.member_id, verify.modified_turn_restrictions.member_role, public.navigable_current.linestring 
FROM verify.modified_turn_restrictions, public.navigable_current
WHERE verify.modified_turn_restrictions.linestring =  public.navigable_current.linestring);

delete from verify.modified_turn_restrictions where id in (select id from verify.turn_restriction_modified_geom_to_delete);

drop table if exists verify.turn_restriction_modified;
drop table if exists verify.turn_restriction_modified_members;
drop table if exists verify.turn_restriction_modified_geom_to_delete; 

--- select deleted signpost tags

create table verify.verify_modified_signpost as (
select public.ways.id as id_public, public.ways.linestring as linestring_public, public.ways.tags as tags_public, verify.signpost_all_verify.id as id_verify, verify.signpost_all_verify.tags as tags_verify,
verify.signpost_all_verify.linestring as linestring_verify from public.ways, verify.signpost_all_verify where
public.ways.id = verify.signpost_all_verify.id and (public.ways.tags->'destination' is null and verify.signpost_all_verify.tags?'destination' or 
public.ways.tags->'destination:ref' is null and verify.signpost_all_verify.tags?'destination:ref' or public.ways.tags->'destination:street' is null and verify.signpost_all_verify.tags?'destination:street'));

create table verify.modified_singpost as (
select * from verify.verify_modified_signpost where tags_verify->'destination' not like tags_public->'destination:street' 
and tags_verify->'destination:street' not like tags_public->'destination');

drop table if exists verify.verify_modified_signpost;
drop table if exists verify.signpost_all_verify;
drop table if exists verify.signpost_tag;
drop table if exists verify.signpost_tag2;








