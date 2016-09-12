-- the following query lists all ACTIVE Forums modules in your DNN - with the pages they reside on.
-- note: only forum modules with ForumType "Standard" can be migrated (due to YAF.Net not supporting DNN Social Groups atm).
-- AF Modules can be migrated one by one only - note the proper ModuleID and enter it into script "Migrate_Forums.sql"

SELECT DISTINCT 
	G.ModuleId,
	T.PortalID,
	T.TabPath as PagePath,
	M.ModuleTitle,
	SettingValue AS ForumMode
 FROM      dbo.activeforums_Groups G
      JOIN dbo.TabModules          M ON G.ModuleID = M.ModuleID
	  JOIN dbo.Tabs				   T ON M.TabID    = T.TabID
 LEFT JOIN dbo.ModuleSettings      S ON M.ModuleID = S.ModuleID AND S.SettingName = N'MODE'
