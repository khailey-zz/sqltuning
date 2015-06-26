# sqltuning
SQL Tuning



* Nikolay_Savvinov,sql	by Nikolay Savvinov , identifies rows in explain plan that look inefficient 
* TCF_LIO_explain_plan.sql by Kyle Hailey, shows LIO per row and cardinality mismatches between actual and expected rows in explain plan
* ash_xplan.sql	 by Tim Gorman, uses ASH to time each line in a explain plan
* ash_xplan_example.txt	Create ash_xplan_example.txt example output from ash_plan.sql
* jonathan_lewis_vst_example.sql - example schema and query 
* showplanfrpspreadsheetcode11g.sql by Kevin Meade - calculates filter ratios for tables in query by reading from the PLAN_TABLE (i.e. you have to run EXPLAIN PLAN first)

The  two_table and three_table files are for creating a two table join and a three table join test case. 
* two_table_join_create.sql - create tables parent and child with indexes. Vars crows and prows set # of rows in child and parent respectively. child has field "pid" which is used to join to parent. It's set up on trunc(id/10) right now so the parent ids are clustered together. Commented out is pid set to mod(id,&prows) which fans the rows out. 
* two_table_join_hj.sql - let oracle optimizer chose join method but run the query twice once with join order parent to child and the other with child to parent
* two_table_join_nl.sql - force nested loop joins. Run query twice with join from child to parent and parent to child.

* three_table_create.sql  - create 3 tables - customer, orders and orderlines. vars crows, orows and olrows define the number of rows in each. orders.cid used to join to customers. orderlines.oid used to join to orders. These reference ids are set up on trunc(id/nrows_parent) thus are clustered. commented out is mod(id,nrows_in_parent) which would fan them out
* three_table_join_hj.sql - let optimizer choose join type which will often be hj but force query join order to be c->o->ol then ol->o->c
* three_table_join_nl.sql - for nl, run twice with orders c->o->ol then ol->o->c. Variable x filters on orderlines where ol.id > &x. 
* three_table_part1_nl.sql - join just two tables c and o, run query twice c->o and o-> c
* three_table_part2_nl.sql - join just two tables o and ol, run query twice o->ol and ol->o
