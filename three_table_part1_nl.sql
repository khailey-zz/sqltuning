define x=100

-- no_swap_join_inputs(c)

select /*+ gather_plan_statistics leading(c,o) use_nl(o) index(o or_cid)  */
        sum(c.val+o.val),
        count(*)
from
        customers c,
        orders o
where
         c.id=o.cid
--     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


select /*+ gather_plan_statistics leading(o,c)  use_nl(c) index(c cu_id)  */
       sum(c.val+o.val),
       count(*)
from
        customers c,
        orders o
where
         c.id=o.cid
--     and ol.id > &x
;
select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));
