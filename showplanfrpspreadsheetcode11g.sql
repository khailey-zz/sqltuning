et pagesize 0
set linesize 1000
set trims on

spool kmo.sql

--
-- script buy Keavin Meade
-- see book "Oracle SQL Performance Tuning and Optimization: It's all about the Cardinalities"
-- see pages 74-76
--
-- generate SQL for the FRP spreadsheet from the most recent plan in the plan_table
--
-- usage is: @SHOWPLANFRPSPREADSHEETCODE11G
--

col actual_frp format 999.0
col plan_frp format 999.0
col select_id noprint

with
--
-- generates a FRP SPREADSHEET query using plan table information for an EXPLAINED query
--
--
-- THIS CODE IS DEPENDENT UPON WHAT IS IN THE PLAN TABLE
-- among other things this means that if oracle changes the contents of this table, this query may stop working
--
-- several possible flaws can prevent this code from generating an executable SQL SELECT
--
-- 1. bind variables: the corresponding select here must be modified to group on the bind column and select an round(avg(count(*))
-- 2. join predicates: if any are used along with constant tests in a plan step, they must be manaully edited out of the correspoding select here
-- 3. packaged functions: column=functioncall predicates can be dropped in which case filtered_cardinality will be affected, check it if you query has these
-- 4. outer join is not supported.  These should be removed.  If the case expression becomes empty use count(*).
-- 5. correlated subqueries are confusing.  This is because the appear as queries with bind variables.  Test like #1 but ingnore their results.
--
--
-- get raw_data from the plan_table for each table reference in the query plan
-- a table may be used more than once in which case there will be more than one row returned here
-- this is managed by using ID so that we know the plan step the table reference refers to
-- note that some plan steps may be index lookups so in this section we translate the index to its underlying table
--
     table_list as (
                     select a.id,a.object_owner table_owner,a.object_name table_name,a.access_predicates,a.filter_predicates,a.object_alias,a.cardinality
                     from plan_table a
                         ,dba_tables b
                     where b.owner = a.object_owner
                     and b.table_name = a.object_name
                     and a.plan_id = (select max(plan_id) from plan_table)
                     union all
                     select a.id,b.table_owner,b.table_name object_name,a.access_predicates,a.filter_predicates,a.object_alias,a.cardinality
                     from plan_table a
                         ,dba_indexes b
                     where b.owner = a.object_owner
                     and b.index_name = a.object_name
                     and a.plan_id = (select max(plan_id) from plan_table)
                   )
--
-- given the raw data for tables, modify the predicates so that we only see predicates for constant tests, no join predicates
-- join predicates are not used in FRP analysis
-- this is a bit of a hack as I never took the COMPILER and PARSER classes in school, basically this means it is almost 100%right
-- what we call "close enough for jazz"
--
    , modified_table_list as (
                               select id,table_owner,table_name,object_alias,cardinality
                             ,case when
                                        instr(replace(access_predicates,'"="'),'=') > 0 or
                                        instr(replace(access_predicates,'">"'),'>') > 0 or
                                        instr(replace(access_predicates,'"<"'),'<') > 0 or
                                        instr(replace(access_predicates,'">="'),'>=') > 0 or
                                        instr(replace(access_predicates,'"<="'),'<=') > 0 or
                                        instr(replace(access_predicates,'"!="'),'!=') > 0 or
                                        instr(replace(access_predicates,'"<>"'),'<>') > 0 or
                                        instr(replace(access_predicates,'" LIKE "'),' LIKE ') > 0 or
                                        instr(replace(access_predicates,'" BETWEEN "'),' BETWEEN ') > 0 or
                                        instr(replace(access_predicates,'" IN ("'),' IN (') > 0 or
                                        instr(replace(access_predicates,'" NOT LIKE "'),' NOT LIKE ') > 0 or
                                        instr(replace(access_predicates,'" NOT BETWEEN "'),' NOT BETWEEN ') > 0 or
                                        instr(replace(access_predicates,'" NOT IN ("'),' NOT IN (') > 0
                                   then access_predicates
                              end access_predicates
                             ,case when
                                        instr(replace(filter_predicates,'"="'),'=') > 0 or
                                        instr(replace(filter_predicates,'">"'),'>') > 0 or
                                        instr(replace(filter_predicates,'"<"'),'<') > 0 or
                                        instr(replace(filter_predicates,'">="'),'>=') > 0 or
                                        instr(replace(filter_predicates,'"<="'),'<=') > 0 or
                                        instr(replace(filter_predicates,'"!="'),'!=') > 0 or
                                        instr(replace(filter_predicates,'"<>"'),'<>') > 0 or
                                        instr(replace(filter_predicates,'" LIKE "'),' LIKE ') > 0 or
                                        instr(replace(filter_predicates,'" BETWEEN "'),' BETWEEN ') > 0 or
                                        instr(replace(filter_predicates,'" IN ("'),' IN (') > 0 or
                                        instr(replace(filter_predicates,'" NOT LIKE "'),' NOT LIKE ') > 0 or
                                        instr(replace(filter_predicates,'" NOT BETWEEN "'),' NOT BETWEEN ') > 0 or
                                        instr(replace(filter_predicates,'" NOT IN ("'),' NOT IN (') > 0
                                   then filter_predicates
                              end filter_predicates
                            from table_list
                             )
--
-- do the final massaging of the raw data
-- in particular, get the true alias for each table, get data from dba_tables, generate an actual predicate we can test with
--
    , plan_info as
                   (
                     select
                              id
                            , table_owner
                            , table_name
                            , substr(object_alias,1,instr(object_alias,'@')-1) table_alias
                            , cardinality
                            , (select num_rows from dba_tables where dba_tables.owner = modified_table_list.table_owner and dba_tables.table_name = modified_table_list.table_name) num_rows
                            , case
                                   when access_predicates is null and filter_predicates is null then null
                                   when access_predicates is null and filter_predicates is not null then filter_predicates
                                   when access_predicates is not null and filter_predicates is null then access_predicates
                                   when access_predicates is not null and filter_predicates is not null and access_predicates != filter_predicates then access_predicates||' and '||filter_predicates
                                   else access_predicates
                              end predicate
                     from modified_table_list
                   )
--
-- look for places where indexes are accessed followed by table acces by rowid
-- combine the two lines into one
--
    , combined_plan_info as (
                              select plan_info.table_owner,plan_info.table_name,plan_info.table_alias,plan_info.cardinality,plan_info.num_rows
                                    ,min(plan_info.id) id
                                    ,listagg(plan_info.predicate,' and ') within group (order by id) predicate
                              from plan_info
                              group by plan_info.table_owner,plan_info.table_name,plan_info.table_alias,plan_info.cardinality,plan_info.num_rows
                            )
--
-- give us a SQL statement that for each table reference, both counts all rows and counts only rows that pass the filter predictes
-- then do the math needed to generate an FRP SPREADSHEET
-- this version (4) only scans each table once instead of twice like the old versions
--
select 1 select_id,'with' sqltext from dual union all
select 2 select_id,'      frp_data as (' from dual union all
select 3 select_id,'                    select '''||lpad(id,5,' ')||''' id,'''||table_owner||''' table_owner,'''||table_name||''' table_name,'''||table_alias||''' table_alias,'||nvl(to_char(num_rows),'cast(null as number)')||' num_rows,count(*) rowcount,'||cardinality||' cardinality,'||decode(predicate,null,'cast(null as number)','count(case when '||predicate||' then 1 end)')||' filtered_cardinality from '||table_owner||'.'||table_name||' '||table_alias||' union all'
                                        from combined_plan_info 
                                        union all
select 4 select_id,'                    select null,null,null,null,null,null,null,null from dual' from dual union all
select 5 select_id,'                  )' from dual union all
select 6 select_id,'select frp_data.*,round(frp_data.filtered_cardinality/case when frp_data.rowcount = 0 then cast(null as number) else frp_data.rowcount end*100,1) actual_frp,decode(frp_data.filtered_cardinality,null,cast(null as number),round(frp_data.cardinality/case when frp_data.num_rows = 0 then cast(null as number) else frp_data.num_rows end*100,1)) plan_frp' from dual union all
select 7 select_id,'from frp_data' from dual union all
select 8 select_id,'where id is not null' from dual union all
select 9 select_id,'order by frp_data.id' from dual union all
select 10 select_id,'/' from dual
order by 1
/

/* output looks like

SQLTEXT
-----------------------------------------------------------------------------
with
frp_data as (
select '   15' id, 'SCOTT' table_owner,'EMPLR_LOC_DIM'
table_name,'E' table_alias,8874 NUM_ROWS,count(*) rowcount,8874
cardinality,count(case when "E"."EMPLR_LOC_PK_ID"<>(-1) AND
"E"."EMPLR_LOC_PK_ID"<>(-2) AND "E"."SRCE_EFF_END_TMSP"=TIMESTAMP' 9999-12-31
00:00:00' then 1 end) filtered_cardinality from EMPLR_LOC_DIM E union all
                    select '    9' id, 'SCOTT' table_owner,'EMP_LOC_DIM'
table_name,'EL' table_alias,329699 NUM_ROWS,count(*) rowcount,296337
cardinality,count(case when "EL"."POPULATION_STATUS_CD"<>'D' then 1 end)
filtered_cardinality from EMP_LOC_DIM EL union all
                    select '    8' id, 'SCOTT' table_owner,'EMP_DIM'
table_name,'EE' table_alias,6243035 NUM_ROWS,count(*) rowcount,240117
cardinality,count(case when "EE"."SRCE_EFF_END_TMSP"=TIMESTAMP' 9999-12-31
00:00:00' AND "EE"."SRCE_APP_SYS_CD"='ELIG' then 1 end) filtered_cardinality
from EMP_DIM EE union all
                    select '   19' id, 'SCOTT' table_owner,'EMP_DIM'
table_name,'EE' table_alias,6243035 NUM_ROWS,count(*) rowcount,240117
cardinality,count(case when "EE"."SRCE_EFF_END_TMSP"=TIMESTAMP' 9999-12-31
00:00:00' AND "EE"."POPULATION_STATUS_CD"<>'D' AND "EE"."EMP_PK_ID"<>(-1) AND
"EE"."EMP_PK_ID"<>(-2) then 1 end) filtered_cardinality from EMP_DIM EE union
all
                    select '   21' id, 'SCOTT' table_owner,'EMP_LOC_DIM'
table_name,'EL' table_alias,329699 NUM_ROWS,count(*) rowcount,251761
cardinality,count(case when "EL"."SRCE_EFF_END_TMSP"=TIMESTAMP' 9999-12-31
00:00:00' AND "EL"."POPULATION_STATUS_CD"<>'D' then 1 end) filtered_cardinality
from EMP_LOC_DIM EL union all
                    select null,null,null,null,null,null,null,null from dual
                  )
select frp_data.*,round(frp_data.filtered_cardinality/case when
frp_data.rowcount = 0 then cast(null as number) else frp_data.rowcount
end*100,1) actual_frp,decode(frp_data.filtered_cardinality,null,cast(null as
number),round(frp_data.cardinality/case when frp_data.NUM_ROWS = 0 then
cast(null as number) else frp_data.NUM_ROWS end*100,1)) plan_frp
from frp_data
where id is not null
order by frp_data.id
;
19 rows selected.
Then run the above query
Plan    Filtered Actual
ID    TABLE_NAME      NUM_ROWS   ROWCOUNT Cardinality Cardinality    FRP
----- ------------- ---------- ---------- ----------- ----------- ------
    8 EMP_DIM          6243035    6243035      240117      215414    3.5
    9 EMP_LOC_DIM       329699     329699      296337      329699  100.0
   15 EMPLR_LOC_DIM       8874       8874        8874        8872  100.0
   19 EMP_DIM          6243035    6243035      240117      236469    3.8
   21 EMP_LOC_DIM       329699     329699      251761      212993   64.6
5 rows selected.
*/

spool off
set pagesize 100




