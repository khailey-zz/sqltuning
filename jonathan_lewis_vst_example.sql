drop table customers;
Create table
    customers
        (  id            number,
           location      varchar2(40) , /* 'LONDON' */
           customer_data varchar2(40),
           CONSTRAINT
           customers_pk  UNIQUE (id)
        );
insert into customers select rownum, owner, object_name from all_objects where rownum < 14577;
update customers set location='LONDON' where location='PUBLIC' and rownum < 50 ;
commit;

drop table jrders;
Create table
    orders
        (  id            number,
           id_customer   number,
           date_placed   date,
               order_data    varchar2(40),
           CONSTRAINT
           orders_pk     UNIQUE (id)
        );
insert into orders select rownum, mod(rownum,998) +1 , (sysdate - dbms_random.value(0,14)), object_name from all_objects where rownum < 50998;
insert into orders select id + 60000, id_customer, date_placed - 7, order_data from  orders;
insert into orders select id + 120000, id_customer, date_placed - 7, order_data from  orders;
commit;

drop table order_lines ;
Create table
    order_lines
        (  id_order        number,
           id_product      number,
           order_line_data varchar2(40)
        );
insert into order_lines select mod(rownum,10000), mod(rownum,200)+1, /* don't include all products */ object_name from all_objects;
insert into order_lines select * from order_lines;
insert into order_lines select * from order_lines;
insert into order_lines select * from order_lines;
insert into order_lines select * from order_lines;
commit;

drop table products ;
Create table
    products
        (  id              number,
           id_supplier     number,
           product_data    varchar2(40),
           CONSTRAINT
           products_pk UNIQUE (id)
        );

insert into products select rownum, mod(rownum,100), object_name from all_objects where rownum < 2000;

rop table suppliers ;
Create table
    suppliers
        (  id             number,
           location       varchar2(40),/* 'LEEDS' */
           supplier_data  varchar2(40),
           CONSTRAINT
           suppliers_pk UNIQUE (id)
        );
insert into suppliers select rownum, owner, object_name from all_objects where rownum < 100;
update suppliers set location='LEEDS' where rownum < 50;
commit;

drop table alternatives   ;
Create table
    alternatives
        (
           id_product   number,
           id_product_sub   number
        );
insert into alternatives select rownum, rownum+10 from all_objects where rownum <50000;
     commit;
drop index alt_i;
create unique index alt_i on alternatives(id_product);

create or replace view v_alternatives as (
        select  alt.id_product
        FROM  alternatives    alt
      INNER JOIN products prd2   ON prd2.id = alt.id_product_sub
      INNER JOIN suppliers sup2  ON sup2.id = prd2.id_supplier
    WHERE    sup2.location != 'LEEDS');

BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'SUPPLIERS'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'PRODUCTS'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'ORDERS'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'ORDER_LINES'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'CUSTOMERS'); END;
/
BEGIN DBMS_STATS.GATHER_TABLE_STATS(null,'ALTERNATIVES'); END;
/

SELECT order_line_data
FROM           customers cus
    INNER JOIN orders ord ON ord.id_customer = cus.id
    INNER JOIN order_lines orl ON orl.id_order = ord.id
    INNER JOIN products prd1 ON prd1.id = orl.id_product
    INNER JOIN suppliers sup1 ON sup1.id = prd1.id_supplier
WHERE   cus.location = 'LONDON'
    AND ord.date_placed BETWEEN sysdate - 7
                        AND     sysdate
    AND sup1.location = 'LEEDS'
    AND EXISTS ( SELECT  NULL
                 FROM  alternatives    alt
                       INNER JOIN     products prd2
                         ON prd2.id = alt.id_product_sub
                       INNER JOIN     suppliers sup2
                         ON sup2.id = prd2.id_supplier
                 WHERE    alt.id_product = prd1.id
                       AND sup2.location != 'LEEDS' )
        ;

