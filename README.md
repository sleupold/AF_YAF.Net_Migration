# AF_YAF.Net_Migration
Script to migrate DNN Active Forums to DNN YAF.Net Forum
-
&copy; Sebastian Leupold, dnnWerk 2016. 

Script is provided "as is" with no liabilities or guarantees.

---

Prerequesites
-
- You need to have Active Forums installed (V 5.0+)
- You need to have YAF.Net module installed with Qualifier "yaf_"
- You need to have Yaf.Net module placed on a page and configured it 
to create board #1. This board with first category and first forum 
will be used as a template for imported data. If you prefere to use 
a different board, you need to modify the migration script. 

Migration
-
*Please make sure you start with a database backup!*

Run ListModules.sql to get a list of migratable AF moduleIds. Enter the 
preferred moduleID into MigrateForums.sql and execute the script.

---
Known issues
-
Script not finished yet!!!
