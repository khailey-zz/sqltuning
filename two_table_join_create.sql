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
--        mod(rownum,&prows)+1 pid
        trunc((rownum-1)/&prows)+1 pid
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

