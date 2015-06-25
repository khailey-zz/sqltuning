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


/*
-------------------------------------------------------------------------------------------------
| Id  | Operation		      | Name   | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	      |        |      1 |	 |	1 |00:00:00.01 |     115 |
|   1 |  SORT AGGREGATE 	      |        |      1 |      1 |	1 |00:00:00.01 |     115 |
|   2 |   NESTED LOOPS		      |        |      1 |	 |     90 |00:00:00.01 |     115 |
|   3 |    NESTED LOOPS 	      |        |      1 |     91 |    100 |00:00:00.01 |      15 |
|   4 |     TABLE ACCESS FULL	      | PARENT |      1 |     10 |     10 |00:00:00.01 |      12 |
|*  5 |     INDEX RANGE SCAN	      | C_PID  |     10 |     10 |    100 |00:00:00.01 |       3 |
|*  6 |    TABLE ACCESS BY INDEX ROWID| CHILD  |    100 |      9 |     90 |00:00:00.01 |     100 |
--------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
| Id  | Operation		       | Name	| Starts | E-Rows | A-Rows |   A-Time	| Buffers |
---------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	       |	|      1 |	  |	 1 |00:00:00.01 |     184 |
|   1 |  SORT AGGREGATE 	       |	|      1 |	1 |	 1 |00:00:00.01 |     184 |
|   2 |   NESTED LOOPS		       |	|      1 |	  |	90 |00:00:00.01 |     184 |
|   3 |    NESTED LOOPS 	       |	|      1 |     91 |	90 |00:00:00.01 |      94 |
|   4 |     TABLE ACCESS BY INDEX ROWID| CHILD	|      1 |     91 |	90 |00:00:00.01 |      91 |
|*  5 |      INDEX RANGE SCAN	       | C_ID	|      1 |     91 |	90 |00:00:00.01 |	1 |
|*  6 |     INDEX RANGE SCAN	       | P_ID	|     90 |	1 |	90 |00:00:00.01 |	3 |
|   7 |    TABLE ACCESS BY INDEX ROWID | PARENT |     90 |	1 |	90 |00:00:00.01 |      90 |
---------------------------------------------------------------------------------------------------

*/
