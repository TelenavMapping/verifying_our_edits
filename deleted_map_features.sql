--1
create table verify.deleted_ways as (select verify.navigable_verify.id, verify.navigable_verify.fc, verify.navigable_verify.tags->'highway' as highway, verify.navigable_verify.linestring from verify.navigable_verify where not exists ( select id from public.navigable_current where public.navigable_current.id = verify.navigable_verify.id)); 

--2
alter table verify.deleted_ways add column buffer geometry; 

update verify.deleted_ways set buffer = st_buffer(linestring, 0.0001);

--3
CREATE TABLE verify.deleted_final_road_geometry AS (
SELECT 
  deleted.id,
  deleted.fc,
  deleted.highway,
  deleted.linestring
FROM 
 verify.deleted_ways AS deleted LEFT JOIN
 public.navigable_current AS nav2 ON
  ST_Intersects(deleted.buffer,nav2.linestring)
WHERE nav2.linestring IS NULL);

delete from verify.deleted_final_road_geometry where verify.deleted_final_road_geometry.linestring is null;

DROP TABLE IF EXISTS verify.deleted_ways;


--- table with restrictions verify

create table verify.restrictions_verify as (
select verify.relations.* from verify.relations WHERE verify.relations.tags-> 'type' = 'restriction');

--- table with restrictions public

create table public.restrictions_current as (
select public.relations.* from public.relations WHERE public.relations.tags-> 'type' = 'restriction');


 --- detect deleted TRs

create table verify.deleted_tr as (select verify.restrictions_verify.id, verify.restrictions_verify.version, verify.restrictions_verify.user_id, verify.restrictions_verify.tags from verify.restrictions_verify where not exists ( select id from public.restrictions_current where public.restrictions_current.id = verify.restrictions_verify.id));

 

--- match deleted TRs with geometry join deleted_tr with relation_members to see what relation_id are deleted

create table verify.deleted_tr_members as (
select verify.deleted_tr.id, verify.deleted_tr.version, verify.deleted_tr.user_id, verify.deleted_tr.tags, verify.relation_members.member_id, verify.relation_members.member_role from verify.deleted_tr, verify.relation_members WHERE verify.deleted_tr.id = verify.relation_members.relation_id);

 

--- match deleted_tr_members with ways (geometry)

create table verify.deleted_final_tr as
(select verify.deleted_tr_members.id, verify.deleted_tr_members.version, verify.deleted_tr_members.user_id, verify.deleted_tr_members.tags, verify.deleted_tr_members.member_id, verify.deleted_tr_members.member_role, verify.navigable_verify.linestring 
FROM verify.deleted_tr_members, verify.navigable_verify
WHERE verify.deleted_tr_members.member_id = verify.navigable_verify.id);


--4
DROP TABLE IF EXISTS verify.deleted_tr;
DROP TABLE IF EXISTS verify.deleted_tr_members;


