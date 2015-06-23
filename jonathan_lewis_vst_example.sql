/*
SELECT order_line_data
FROM           jl_customers cus
    INNER JOIN jl_orders ord ON ord.id_customer = cus.id
    INNER JOIN jl_order_lines orl ON orl.id_order = ord.id
    INNER JOIN jl_products prd1 ON prd1.id = orl.id_product
    INNER JOIN jl_suppliers sup1 ON sup1.id = prd1.id_supplier
WHERE   cus.location = 'LONDON'
    AND ord.date_placed BETWEEN sysdate - 7 
                        AND     sysdate
    AND sup1.location = 'LEEDS'
    AND EXISTS ( SELECT  NULL
                 FROM  jl_alternatives    alt
                       INNER JOIN     jl_products prd2
                         ON prd2.id = alt.id_product_sub
                       INNER JOIN     jl_suppliers sup2 
                         ON sup2.id = prd2.id_supplier
                 WHERE    alt.id_product = prd1.id
                       AND sup2.location != 'LEEDS' )
	;
*/

drop table jl_customers;
Create table
    jl_customers 
        (  id            number,
           location      varchar2(40) , /* 'LONDON' */
	   customer_data varchar2(40),
           CONSTRAINT 
           jl_customers_pk  UNIQUE (id)
        );
insert into jl_customers select rownum, owner, object_name 
from all_objects where rownum < 1000;
 update jl_customers set location='LONDON' where location='PUBLIC';

drop table jl_orders;
Create table
    jl_orders 
        (  id            number,
           id_customer   number,
           date_placed   date,
	       order_data    varchar2(40),
           CONSTRAINT 
           jl_orders_pk     UNIQUE (id)
        );

insert into jl_orders select
       rownum,
       mod(rownum,998) +1 ,
       (sysdate - dbms_random.value(0,100)), 
       object_name
from all_objects where rownum < 10000;

drop table jl_order_lines ;
Create table
    jl_order_lines 
        (  id_order        number,
           id_product      number,
	   order_line_data varchar2(40)
        );
insert into jl_order_lines 
select mod(rownum,10000),
       mod(rownum,200)+1, /* don't include all products */
       object_name
from all_objects;
commit;
SELECT COUNT (*) FROM SYSTEM.JL_PRODUCTS prd1, SYSTEM.JL_ORDER_LINES orl
 WHERE prd1.id = orl.id_product
;
select max(id_product), min(id_product) from jl_order_lines;

drop table jl_products ;
Create table
    jl_products 
        (  id              number,
           id_supplier     number,
	   product_data    varchar2(40),
           CONSTRAINT 
           jl_products_pk UNIQUE (id)
	);

insert into jl_products 
select rownum,
       mod(rownum,100),
       object_name
from all_objects where rownum < 2000;

drop table jl_suppliers ;
Create table
    jl_suppliers 
        (  id             number,
           location       varchar2(40),/* 'LEEDS' */
	   supplier_data  varchar2(40),
           CONSTRAINT 
           jl_suppliers_pk UNIQUE (id)
        );

insert into jl_suppliers 
select rownum,
       owner,
       object_name
from all_objects where rownum <100;
 update jl_suppliers set location='LEEDS' where rownum < 10;


drop table jl_alternatives   ; 
Create table
    jl_alternatives    
        (  
	   id_product   number,
	   id_product_sub   number
        );
insert into jl_alternatives 
    select
       rownum,
       rownum+10
     from all_objects where rownum <100;
     commit;
create unique index alt_i on jl_alternatives(id_product);

create view v_alternatives as (
	select  alt.id_product
	FROM  jl_alternatives    alt
      INNER JOIN jl_products prd2   ON prd2.id = alt.id_product_sub
      INNER JOIN jl_suppliers sup2  ON sup2.id = prd2.id_supplier
    WHERE    sup2.location != 'LEEDS');

/*
SELECT order_line_data
FROM           jl_customers cus
    INNER JOIN jl_orders ord ON ord.id_customer = cus.id
    INNER JOIN jl_order_lines orl ON orl.id_order = ord.id
    INNER JOIN jl_products prd1 ON prd1.id = orl.id_product
    INNER JOIN jl_suppliers sup1 ON sup1.id = prd1.id_supplier
WHERE   cus.location = 'LONDON'
    AND ord.date_placed BETWEEN sysdate - 7 
                        AND     sysdate
    AND sup1.location = 'LEEDS'
    AND EXISTS ( SELECT  NULL
                 FROM  v_alternatives   
                 WHERE    alt.id_product = prd1.id
	);
*/
