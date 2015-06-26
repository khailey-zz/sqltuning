def crows=10
def orows=100
def olrows=1000

drop table customers;
create table customers as
select
        rownum id
        ,rownum val
        ,rpad('A',4000,'A') data1
        ,rpad('A',2000,'A') data2
from
        dual
connect by
        level <= &crows
;

drop table orders;
create table orders as
select
        rownum   id,
        --mod(rownum,&crows)+1 cid
        trunc((rownum-1)/&crows)+1 cid
        ,rownum val
        ,rpad('A',4000,'A') data1
        ,rpad('A',2000,'A') data2
from
        dual
connect by
        level <= &orows
;

drop table orderlines;
create table orderlines as
select
        rownum   id,
        --mod(rownum,&orows)+1 oid
        trunc((rownum-1)/&orows)+1 oid
        ,rownum val
        ,rpad('A',4000,'A') data1
        ,rpad('A',2000,'A') data2
from
        dual
connect by
        level <= &olrows
;

create index cu_id   on customers(id);
create index or_id   on orders(id);
create index or_cid  on orders(cid);
create index ol_id  on orderlines(id);
create index ol_oid on orderlines(oid);

BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'CUSTOMERS'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'ORDERS'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'ORDERLINES'); END;
