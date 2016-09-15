/* 
   *******************************************************************
   *  SQL Script to migrate DNN active Forum to YAF.Net DNN module   *
   *  ============================================================   *
   *                                                                 *
   *  (c) Sebastian Leupold, dnnWerk, 2016                           *
   *                                                                 *
   *******************************************************************
*/
-- extend table structure to perform the conversion
IF NOT Exists (SELECT * FROM sys.columns where object_id = OBJECT_ID(N'dbo.yaf_board')    and name = N'oModuleID')
  ALTER TABLE dbo.yaf_board    ADD oModuleID Int Null;

IF NOT Exists (SELECT * FROM sys.columns where object_id = OBJECT_ID(N'dbo.yaf_category') and name = N'oGroupID')
  ALTER TABLE dbo.yaf_category ADD oGroupID  Int Null;

IF NOT Exists (SELECT * FROM sys.columns where object_id = OBJECT_ID(N'dbo.yaf_forum')    and name = N'oForumID')
  ALTER TABLE dbo.yaf_forum    ADD oForumID  Int Null;


GO

/* Specify your original moduleID here:               */
DECLARE @oModuleID int = -1; 
/*                       ^ replace with your ModuleID */
/* -------------------------------------------------- */

-- Create YAF.Net Boards in table yaf_board
INSERT INTO dbo.yaf_Board 
       (Name, allowThreaded, MembershipAppName, RolesAppName, oModuleID) 
SELECT ModuleTitle, 1, N'', N'', ModuleID
 FROM  dbo.TabModules 
 WHERE TabModuleID IN (SELECT Min(TabModuleID) FROM dbo.TabModules WHERE ModuleID = @oModuleID);

-- get the boardID:
DECLARE @boardID int = (SELECT BoardID FROM dbo.yaf_Board WHERE oModuleID = @oModuleID);

-- create accessMasks:
MERGE INTO dbo.yaf_AccessMask  T
USING (SELECT @boardID as BoardID, N'Admin Access' AS [Name], 2047 AS Flags, 4 AS SortOrder
       UNION ALL SELECT @boardID, N'Moderator Access', 1511, 3
       UNION ALL SELECT @boardID, N'Member Access', 1447, 2,
       UNION ALL SELECT @boardID, N'Read Only Access', 1, 1,
       UNION ALL SELECT @boardID, N'No Access', 0, 0, 
      ) S ON T.BoardID = S.BoardID and T.SortOrder = S.SortOrder
WHEN NOT MATCHED THEN INSERT (  BoardID, [Name], [Flags],   SortOrder) 
                      VALUES (S.BoardID, S.Name, S.Flags, S.SortOrder);

-- Copy over Roles
MERGE INTO dbo.yaf_Roles T
USING (SELECT FROM dbo.Roles R JOIN dbo.ModulePermission P ON R.RoleID = P.RoleID AND P.ModuleID = @oModuleID) S 
   ON T.BoardID = @BoardID AND T.Name = S.RoleName
WHEN NOT MATCHED THEN INSERT (BoardID, [Name],    [Flags], PMLimit, Style, SortOrder, Description, UsrSigChars, UsrSigBBCodes, UsrSigHTMLTags, UsrAlbum, UsrAlbumImages, IsHidden, IsUsrGroup) 
                      VALUES (@BoardID, S.RoleName,    );

-- Populate Ranks:
-- Populate Smileys: 
-- Populate SpamWord: 

-- Populate Aspnet_Roles: 
DECLARE @appGuid uniqueIdentifier = (SELECT ApplicationID FROM dbo.aspnet_application WHERE ApplicationName = N'DotNetNuke' OR ApplicationName = N'DNN');
MERGE INTO dbo.aspnet_Roles T
USING dbo.yaf_Roles S ON T.RoleName = S.RoleName and S.BoardID = @BoardID
WHEN NOT MATCHED THEN INSERT (ApplicationID, RoleID, RoleName, LoweredRoleName, Description) 
                      VALUES (@appGuid,  NewID(), S.RoleName, Lower(S.RoleName), Null);


-- Populate Users: 
-- Populate UserProfile: 
-- Populate UserGroup:

-- Copy module settings and permissions:

-- Copy AF Forum Groups to YAF.Net Categories
MERGE INTO dbo.yaf_category T
USING dbo.activeforums_Groups S ON T.BoardID = @BoardID AND S.ModuleID = @oModuleID AND T.Name = S.GroupName 
WHEN NOT MATCHED THEN INSERT (BoardID, [Name], CategoryImage, SortOrder, PollgroupID, oGroupID) 
                      VALUES (@oModuleID,  GroupName, N'categoryImageSample.gif', S.SortOrder, Null, S.ForumGroupID);

-- Copy AF Forums to YAF.Net Forums
MERGE INTO dbo.yaf_forum T
USING (SELECT F.*, C.CategoryID 
        FROM  dbo.activeforums_Forums F
        JOIN  dbo.yaf_categories      C ON F.ForumGroupID = C.oGroupID) S
   ON S.CategoryID = T.CategoryID AND T.Name = S.ForumName 
WHEN NOT MATCHED THEN INSERT (  CategoryID, ParentID, [Name],  Description, SortOrder, Flags, IsLocked, isHidden, IsNoCount, IsModerated, ThemeURL, PollGroupID, ImageURL, Styles, IsModeratedNewTopic, oForumID) 
                      VALUES (S.CategoryID, Null, S.ForumName, S.ForumDesc, S.SortOrder,   4,        0,        0,         1,           0,     Null,        Null,     Null,   Null,                  0, S.ForumID);

-- Copy Threads

-- Copy Posts/replies

-- Copy Notifications (yaf_Watch)

GO

Exec dbo.[yaf_forum_resync] @BoardID;

-- Undo Table modifications:
IF Exists (SELECT * FROM sys.columns where object_id = OBJECT_ID(N'dbo.yaf_forum') and name = N'oForumID')
  ALTER TABLE dbo.yaf_forum DROP oForumID;
GO

IF Exists (SELECT * FROM sys.columns where object_id = OBJECT_ID(N'dbo.yaf_category') and name = N'oGroupID')
  ALTER TABLE dbo.yaf_category DROP oGroupID;
GO

IF Exists (SELECT * FROM sys.columns where object_id = OBJECT_ID(N'dbo.yaf_board') and name = N'oModuleID')
  ALTER TABLE dbo.yaf_board DROP oModuleID;
GO