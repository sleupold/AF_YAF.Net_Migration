# Active Forums to YAF.Net Migration

## Script to migrate DNN Active Forums to DNN YAF.Net Forum

&copy; [Sebastian Leupold](https://github.com/sleupold), [dnnWerk](http://dnnwerk.de) 2016. 

Latest version is available on [GitHub](https://github.com/sleupold/AF_YAF.Net_Migration).

**This Script is provided "as is" with no liabilities or guarantees.**

---
## What will be migrated?

- AF Module → YAF.Net Board
- AF ForumGroups → YAF.Net Categories
- AF Forums → YAF.Net Forums
- AF Threads → YAF.Net Topics
- AF Topics & Replies → YAF.Net Messages
- AF Attachments → YAF.Net Attachments
- AF Notifications → YAF.Net Forum & Topic Watches
- DNN Users with forum posts → YAF.Net Users
- DNN Roles with AF module permission → YAF.Net Groups & ASP.net Roles

## What will not be migrated?

- Permissions and a number of settings for forums and forum groups
- Messages (if you are still using AF Messages, I suggest migrating it to Core Messages)
- YAF.Net does not support forums for DNN Social Groups, i.e. those AF forum modules cannot be migrated atm!
- Data from Polls

## Prerequisites

- You need to have [DNN](https://github.com/dnnsoftware/Dnn.Platform) 
  with [Active Forums](https://github.com/ActiveForums/ActiveForums) installed (V 5.0+).
- You need to have [YAF.Net DNN module](https://github.com/YAFNET/YAFNET-DNN) installed, 
  using default database objet qualifier "yaf_".
- Make sure, there are no open polls, because those will not be copied over.
- You should inform your users to dismiss all notification messages, 
  as they will get lost during migration.
- You need to have Yaf.Net module placed on a page and configured it 
to create board #1. This board with first category and first forum 
will be used as a template for imported data. If you prefere to use 
a different board, you need to modify the migration script. 

## Performing a Migration

**Please make sure you start with a database backup!!!**

- Please make sure you are using latest version of the migration script from [GitHub](https://github.com/sleupold/AF_YAF.Net_Migration).

- In Host > SQL, run ListModules.sql to get a list of migratable AF moduleIds. Enter the 
preferred moduleID into MigrateForums.sql 

- Execute script MigrateForums.sql in Host > SQL or SSMS 

- to get AF file attachements being displayed and provided for download, you need
  to copy manually the files from portals[PortalID]\activeforums_Upload folder 
  to folder \DesktopModules\YetAnotherForumDotNet\uploads
  and append ".yafupload" to each file name.

- Afterwards add a new YAF.Net DNN module instance to a page and select highest existing Board to be displayed.
Enter Board administration and review/adjust permissions and settings for board, forums and forum groups.

- Inform your users about the migration and tell them to review their forum settings.

---
## Known issues

Script not finished yet - work in progress:
- datetime values need to be converted to UTC
- not yet tested
