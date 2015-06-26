define x=1

-- no_swap_join_inputs(c)

select /*+ gather_plan_statistics leading(c,o,ol) use_nl(o) use_nl(ol) index(or o_cid) index(ol ol_oid) */
        sum(c.val+o.val+ol.val),
        count(*)
from
        customers c,
        orders o,
        orderlines ol
where
         c.id=o.cid
     and o.id=ol.oid
--     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


select /*+ gather_plan_statistics leading(ol,o,c) use_nl(o) use_nl(c) index(or o_id) index(c cu_id) */
       sum(c.val+o.val+ol.val),
       count(*)
from
        customers c,
        orders o,
        orderlines ol
where
         c.id=o.cid
     and o.id=ol.oid
--     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));
