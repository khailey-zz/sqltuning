# sqltuning
SQL Tuning



* Nikolay_Savvinov,sql	by Nikolay Savvinov , identifies rows in explain plan that look inefficient 
* TCF_LIO_explain_plan.sql by Kyle Hailey, shows LIO per row and cardinality mismatches between actual and expected rows in explain plan
* ash_xplan.sql	 by Tim Gorman, uses ASH to time each line in a explain plan
* ash_xplan_example.txt	Create ash_xplan_example.txt example output from ash_plan.sql
* jonathan_lewis_vst_example.sql - example schema and query 
* showplanfrpspreadsheetcode11g.sql by Kevin Meade - calculates filter ratios for tables in query by reading from the PLAN_TABLE (i.e. you have to run EXPLAIN PLAN first)
