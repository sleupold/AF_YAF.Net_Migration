-- extend table structure to perform the conversion
IF NOT Exists (SELECT * FROM sys.columns where object_id = OBJECT_ID(N'dbo.yaf_board') and name = N'oModuleID')
  ALTER TABLE dbo.yaf_board ADD oModuleID Int Null;
GO

/* Specify your original moduleID here:               */
DECLARE oModuleID int = -1; 
/*                       ^ replace with your ModuleID */
/* -------------------------------------------------- */

-- Create YAF.Net Boards in table yaf_board
INSERT INTO yaf.Board 
       (Name, allowThreaded, MembershipAppName, RolesAppName, oModuleID) 
SELECT ModuleTitle, 1, N'', N'', ModuleID
 FROM  dbo.TabModules 
 WHERE TabModuleID IN (SELECT Min(TabModuleID) FROM dbo.TabModules WHERE ModuleID = @oModuleID);
 
-- Copy module settings and permissions 

-- Copy AF Forum Groups to YAF.Net Categories

-- Copy AF Forums to YAF.Net Forums

-- Copy Threads

-- Copy Posts/replies

-- Copy Notifications

-- Undo Table modifications
