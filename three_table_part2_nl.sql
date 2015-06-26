define x=900

-- no_swap_join_inputs(c)

select /*+ gather_plan_statistics leading(o,ol) use_nl(ol)  index(ol ol_oid) */
        sum(o.val+ol.val),
        count(*)
from
        orders o,
        orderlines ol
where
           o.id=ol.oid
--     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


select /*+ gather_plan_statistics leading(ol,o) use_nl(o) index(o or_id)  */
       sum(o.val+ol.val),
       count(*)
from
        orders o,
        orderlines ol
where
           o.id=ol.oid
--     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));
