def prows=10
def crows=100

drop table parent;
create table parent as
select
        rownum id
        ,rownum val
        ,rpad('A',4000,'A') data1
        ,rpad('A',2000,'A') data2
from
        dual
connect by
        level <= &prows
;

drop table child;
create table child as
select
        rownum   id,
        mod(rownum,&prows)+1 pid
        ,rownum val
        ,rpad('A',4000,'A') data1
        ,rpad('A',2000,'A') data2
from
        dual
connect by
        level <= &crows
;

create index c_pid on child(pid);
create index c_id on child(id);
create index p_id on parent(id);

BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'CHILD'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'PARENT'); END;
/

define x=30

select /*+ gather_plan_statistics leading(p,c) use_nl(c) index(c c_pid) no_swap_join_inputs(c) */ sum(c.val+p.val), count(*) from parent p, child c
where c.pid=p.id
and c.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


select /*+ gather_plan_statistics leading(c,p) use_nl(p) no_swap_join_inputs(p) index(c c_id) */ sum(c.val+p.val), count(*) from parent p, child c
where c.pid=p.id
and c.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));



