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
/* modify the following id's to match the board, 
  you want to use as template:                        */
DECLARE @tplBoardID    int = 1;
DECLARE @tplCategoryID int = 1;
DECLARE @tplForumID    int = 1;
/* -------------------------------------------------- */
-- N'0;13;|1134;||'
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
USING (SELECT @boardID as BoardID, [Name], [Flags], SortOrder FROM dbo.yaf_AccessMask WHERE BoardID = @tplBoardID) S 
       ON T.BoardID = S.BoardID and T.SortOrder = S.SortOrder
WHEN NOT MATCHED THEN INSERT (  BoardID, [Name], [Flags],   SortOrder) 
                      VALUES (S.BoardID, S.Name, S.Flags, S.SortOrder);

-- Create default Roles:
MERGE INTO dbo.yaf_Group T
USING (SELECT * FROM dbo.yaf_Group WHERE BoardID = @tplBoardID and Flags != 0) S ON T.BoardID = @BoardID AND T.Name = S.Name
WHEN NOT MATCHED THEN INSERT ( BoardID,   [Name],   [Flags],   PMLimit,   Style,   SortOrder,   Description,   UsrSigChars,   UsrSigBBCodes,   UsrSigHTMLTags,   UsrAlbums,   UsrAlbumImages,   IsHidden,   IsUserGroup) 
                      VALUES (@BoardID, S.[Name], S.[Flags]  S.PMLimit, S.Style, S.SortOrder, S.Description, S.UsrSigChars, S.UsrSigBBCodes, S.UsrSigHTMLTags, S.UsrAlbums, S.UsrAlbumImages, S.IsHidden, S.IsUserGroup;

-- Create individual Roles:
MERGE INTO dbo.yaf_Group T
USING (SELECT RoleName FROM dbo.Roles 
        WHERE RoleID     IN (SELECT DISTINCT RoleID FROM dbo.ModulePermission P WHERE P.ModuleID = @oModuleID)
          AND RoleID NOT IN (SELECT RoleID FROM dbo.Roles R JOIN dbo.Portals P ON R.PortalID = P.PortalID JOIN dbo.Modules M ON P.PortalID = M.PortalID  WHERE M.ModuleID = @oModuleID)
      ) S  ON T.BoardID = @BoardID AND T.Name = S.RoleName
WHEN NOT MATCHED THEN INSERT (BoardID, [Name],    [Flags], PMLimit, Style, SortOrder, Description, UsrSigChars, UsrSigBBCodes, UsrSigHTMLTags, UsrAlbums, UsrAlbumImages, IsHidden, IsUserGroup) 
                      VALUES (@BoardID, S.RoleName,     0,       0,  Null,       100,         N'',           0,           N'',            N'',         0,              0,        0,           0);

-- Populate Ranks:
MERGE INTO dbo.yaf_Rank T
USING (SELECT * FROM dbo.yaf_Rank WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.Name = S.Name
WHEN NOT MATCHED THEN INSERT ( BoardID,   [Name],   MinPosts,   RankImage,   Flags,   PMLimit,   Style,   SortOrder,   Description,   UsrSigChars,   UsrSigBBCodes,   UsrSigHTMLTags,   UsrAlbums,   UsrAlbumImages)
                      VALUES (@BoardID, S.[Name], S.MinPosts, S.RankImage, S.Flags, S.PMLimit, S.Style, S.SortOrder, S.Description, S.UsrSigChars, S.UsrSigBBCodes, S.UsrSigHTMLTags, S.UsrAlbums, S.UsrAlbumImages);

-- Populate Smileys: 
MERGE INTO dbo.yaf_Smiley T
USING (SELECT * FROM dbo.yaf_Smiley WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.SortOrder = S.SortORder
WHEN NOT MATCHED THEN INSERT ( BoardID,   [Code],   Icon,   Emoticon,   SortOrder)
                      VALUES (@BoardID, S.[Code], S.Icon, S.Emoticon, S.SortOrder);

-- Populate SpamWords: 
MERGE INTO dbo.yaf_Spam_Words T
USING (SELECT * FROM dbo.yaf_Spam_Words WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.SpamWord = S.SpamWord
WHEN NOT MATCHED THEN INSERT ( BoardID,   SpamWord)
                      VALUES (@BoardID, S.SpamWord);

-- Populate Replace_Words: 
MERGE INTO dbo.yaf_Replace_Words T
USING (SELECT * FROM dbo.yaf_Replace_Words WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.BadWord = S.BadWord
WHEN NOT MATCHED THEN INSERT ( BoardID,   BadWord,   GoodWord)
                      VALUES (@BoardID, S.BadWord, S.GoodWord);

-- Populate Extensions: 
MERGE INTO dbo.yaf_Extension T
USING (SELECT * FROM dbo.yaf_Extension WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.Extension = S.Extension
WHEN NOT MATCHED THEN INSERT ( BoardID,   Extension)
                      VALUES (@BoardID, S.Extension);

-- Populate BBCodes:
MERGE INTO dbo.yaf_BBCode T
USING (SELECT * FROM dbo.yaf_BBCode WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.Name = S.Name
WHEN NOT MATCHED THEN INSERT ( BoardID,   [Name],   Description,   OnClickJS,   DisplayJS,   EditJS,   DisplayCSS,   SearchRegex,   ReplaceRegex,   Variables,   UseModule,   ModuleClass,   ExecOrder)
                      VALUES (@BoardID, S.[Name], S.Description, S.OnClickJS,   DisplayJS, S.EditJS, S.DisplayCSS, S.SearchRegex, S.ReplaceRegex, S.Variables, S.UseModule, S.ModuleClass, S.ExecOrder);

-- Populate TopicStatus:
MERGE INTO dbo.yaf_TopicStatus T
USING (SELECT * FROM dbo.yaf_TopicStatus WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.TopicStatusName = S.TopicStatusName
WHEN NOT MATCHED THEN INSERT ( BoardID,   TopicStatusName,   defaultDescription)
                      VALUES (@BoardID, S.TopicStatusName, S.defaultDescription);

-- Populate Registry:
MERGE INTO dbo.yaf_Registry T
USING (SELECT * FROM dbo.yaf_Registry WHERE BoardID = @tplBoardID) S ON T.BoardID = @BoardID AND T.[Name] = S.[Name]
WHEN NOT MATCHED THEN INSERT ( BoardID,   [Name],   Value)
                      VALUES (@BoardID, S.[Name], S.Value);

-- Populate Aspnet_Roles: 
DECLARE @appGuid uniqueIdentifier = (SELECT ApplicationID FROM dbo.aspnet_applications WHERE ApplicationName = N'DotNetNuke' OR ApplicationName = N'DNN');
MERGE INTO dbo.aspnet_Roles T
USING dbo.yaf_Group S ON T.RoleName = S.Name and S.BoardID = @BoardID
WHEN NOT MATCHED THEN INSERT (ApplicationID, RoleID, RoleName, LoweredRoleName, Description) 
                      VALUES (@appGuid,  NewID(), S.Name, Lower(S.Name), Null);

-- Populate Users: 
   -- guest user:
MERGE INTO dbo.yaf_user T
USING (SELECT * FROM dbo.yaf_User WHERE BoardID = @tplBoardID AND Name = N'Guest') S ON T.BoardID = @BoardID and T.Name = S.Name
WHEN NOT MATCHED THEN INSERT ( BoardID,   ProviderUserKey,   Name,   DisplayName,   Password,   Email,   Joined,   LastVisit,   IP,   NumPosts,   TimeZone,   Avatar,   Signature,   AvatarImage,   AvatarImageType,   RankID,   Suspended,   SuspendedReason,   SuspendedBy,   LanguageFile,   ThemeFile,   TextEditor,   OverridedefaultThemes,   PMNotification,   AutoWatchTopics,   DailyDigest,   NotificationType,   Flags,   Points,   IsApproved,   IsGuest,   IsCaptchaExcluded,   IsActiveExcluded,   IsDST,   IsDirty,   Culture,   IsFacebookUser,   IsTwitterUser,   UserStyle,   StyleFlags,   IsUserStyle,   IsGroupStyle,   IsRankStyle,   IsGoogleUser) 
                      VALUES (@BoardID, S.ProviderUserKey, S.Name, S.DisplayName, S.Password, S.Email, S.Joined, S.LastVisit, S.IP, S.NumPosts, S.TimeZone, S.Avatar, S.Signature, S.AvatarImage, S.AvatarImageType, S.RankID, S.Suspended, S.SuspendedReason, S.SuspendedBy, S.LanguageFile, S.ThemeFile, S.TextEditor, S.OverridedefaultThemes, S.PMNotification, S.AutoWatchTopics, S.DailyDigest, S.NotificationType, S.Flags, S.Points, S.IsApproved, S.IsGuest, S.IsCaptchaExcluded, S.IsActiveExcluded, S.IsDST, S.IsDirty, S.Culture, S.IsFacebookUser, S.IsTwitterUser, S.UserStyle, S.StyleFlags, S.IsUserStyle, S.IsGroupStyle, S.IsRankStyle, S.IsGoogleUser);

   -- all other users, who ever created a post:
MERGE INTO dbo.yaf_user T
USING (SELECT * FROM dbo.vw_xUsers) S ON T.BoardID = @BoardID and T.Name = S.Name
WHEN NOT MATCHED THEN INSERT ( BoardID,   ProviderUserKey,   Name,   DisplayName,   Password,   Email,   Joined,   LastVisit,   IP,   NumPosts,   TimeZone,   Avatar,   Signature,   AvatarImage,   AvatarImageType,   RankID,   Suspended,   SuspendedReason,   SuspendedBy,   LanguageFile,   ThemeFile,   TextEditor,   OverridedefaultThemes,   PMNotification,   AutoWatchTopics,   DailyDigest,   NotificationType,   Flags,   Points,   IsApproved,   IsGuest,   IsCaptchaExcluded,   IsActiveExcluded,   IsDST,   IsDirty,   Culture,   IsFacebookUser,   IsTwitterUser,   UserStyle,   StyleFlags,   IsUserStyle,   IsGroupStyle,   IsRankStyle,   IsGoogleUser) 
                      VALUES (@BoardID, ...);

-- Populate UserProfile: 
MERGE INTO dbo.yaf_userProfile T
USING (SELECT * FROM dbo.vw_xProfile) S ON T.BoardID = @BoardID and T.UserID = S.UserID
WHEN NOT MATCHED THEN INSERT ()
                      VALUES ();

-- Populate UserGroups:
MERGE INTO dbo.yaf_userGroup T
USING (SELECT UserId, GroupID FROM ) S ON T.UserID = S.UserID and T.GroupID = S.GroupID
WHEN NOT MATCHED THEN INSERT (UserID, GroupID) VALUES (S.UserID, S.GroupID);

-- Populate aspnet_usersInRoles:
MERGE INTO dbo.aspnet_usersInRoles T
USING (SELECT UserId, RoleID FROM ) S ON T.UserID = S.UserID and T.RoleID = S.RoleID
WHEN NOT MATCHED THEN INSERT (UserID, RoleID) VALUES (S.UserID, S.RoleID);

-- Copy AF Forum Groups to YAF.Net Categories:
MERGE INTO dbo.yaf_category T
USING dbo.activeforums_Groups S ON T.BoardID = @BoardID AND S.ModuleID = @oModuleID AND T.Name = S.GroupName 
WHEN NOT MATCHED THEN INSERT (BoardID, [Name], CategoryImage, SortOrder, PollgroupID, oGroupID) 
                      VALUES (@oModuleID,  GroupName, N'categoryImageSample.gif', S.SortOrder, Null, S.ForumGroupID);

-- Copy AF Forums to YAF.Net Forums:
MERGE INTO dbo.yaf_forum T
USING (SELECT F.*, C.CategoryID 
        FROM  dbo.activeforums_Forums F
        JOIN  dbo.yaf_category        C ON F.ForumGroupID = C.oGroupID) S
   ON S.CategoryID = T.CategoryID AND T.Name = S.ForumName 
WHEN NOT MATCHED THEN INSERT (  CategoryID, ParentID, [Name],  Description, SortOrder, Flags, IsLocked, isHidden, IsNoCount, IsModerated, ThemeURL, PollGroupID, ImageURL, Styles, IsModeratedNewTopicOnly, oForumID) 
                      VALUES (S.CategoryID, Null, S.ForumName, S.ForumDesc, S.SortOrder,   4,        0,        0,         1,           0,     Null,        Null,     Null,   Null,                      0, S.ForumID);

-- Copy Threads:
MERGE INTO dbo.yaf_topic T
USING (SELECT ) S
WHEN NOT MATCHED THEN INSERT ()
                      VALUES ();
-- Copy Posts/replies:
MERGE INTO dbo.yaf_Message T
USING (SELECT ) S
WHEN NOT MATCHED THEN INSERT ()
                      VALUES ();

-- Copy Attachments:
MERGE INTO dbo.yaf_Attachment T
USING (SELECT ) S
WHEN NOT MATCHED THEN INSERT ()
                      VALUES ();

-- Copy Notifications (yaf_Watch):
MERGE INTO dbo.yaf_WatchForum T
USING (SELECT ) S
WHEN NOT MATCHED THEN INSERT ()
                      VALUES ();

MERGE INTO dbo.yaf_WatchTopic T
USING (SELECT ) S
WHEN NOT MATCHED THEN INSERT ()
                      VALUES ();

-- Copy group & forum permission // skipped due to incompatible Permission format, please set manually

Exec dbo.[yaf_forum_resync] @BoardID;

GO

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