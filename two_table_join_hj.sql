define x=10


select /*+ gather_plan_statistics leading(p,c)  */
      sum(c.val+p.val), count(*) from parent p, child c
where
      c.pid=p.id
  and c.id > &x
;

select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


select /*+ gather_plan_statistics leading(c,p) */
      sum(c.val+p.val), count(*) from parent p, child c
where
      c.pid=p.id
  and c.id > &x
;

select * from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));
