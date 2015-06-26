define x=500

-- no_swap_join_inputs(c)

select /*+ gather_plan_statistics leading(c,o,ol) */
        sum(c.val+o.val+ol.val),
        count(*)
from
        customers c,
        orders o,
        orderlines ol
where
         c.id=o.cid
     and o.id=ol.oid
     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


select /*+ gather_plan_statistics leading(ol,o,c) */
       sum(c.val+o.val+ol.val),
       count(*)
from
        customers c,
        orders o,
        orderlines ol
where
         c.id=o.cid
     and o.id=ol.oid
     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));
