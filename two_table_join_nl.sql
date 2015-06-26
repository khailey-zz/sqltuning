define x=10


--select /*+ gather_plan_statistics leading(p,c) use_nl(c) */ sum(c.val+p.val) from parent p, child c
select /*+ gather_plan_statistics leading(p,c) use_nl(c) index(c c_pid) no_swap_join_inputs(c) */ sum(c.val+p.val), count(*) from parent p, child c
where c.pid=p.id
and c.id > &x
;

select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


--select /*+ gather_plan_statistics leading(p,c) use_nl(c) index(c c_pid) */ sum(c.val+p.val) from parent p, child c

select /*+ gather_plan_statistics leading(c,p) use_nl(p) no_swap_join_inputs(p) index(c c_id) */ sum(c.val+p.val), count(*) from parent p, child c
where c.pid=p.id
and c.id > &x
;

select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));
