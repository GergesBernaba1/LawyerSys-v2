IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20251207233318_InitialLegacyBaseline'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20251207233318_InitialLegacyBaseline', N'8.0.0');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    ALTER TABLE [Cases] ADD [Status] int NOT NULL DEFAULT 0;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [__EFMigrationsHistory_Legacy] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory_Legacy] PRIMARY KEY ([MigrationId])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AdminstrativeTasks] (
        [Id] int NOT NULL IDENTITY,
        [Task_Name] nvarchar(50) NOT NULL,
        [Type] nvarchar(50) NOT NULL,
        [Task_Date] date NOT NULL,
        [Task_Reminder_Date] datetime NOT NULL,
        [Notes] nvarchar(50) NOT NULL,
        [employee_Id] int NULL,
        CONSTRAINT [PK_AdminstrativeTasks] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AdminstrativeTasks_AdminstrativeTasks] FOREIGN KEY ([employee_Id]) REFERENCES [Employees] ([id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [App_Pages] (
        [Id] int NOT NULL IDENTITY,
        [Page_Name] nvarchar(50) NOT NULL,
        CONSTRAINT [PK_App_Pages] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AspNetRoles] (
        [Id] nvarchar(450) NOT NULL,
        [Name] nvarchar(256) NULL,
        [NormalizedName] nvarchar(256) NULL,
        [ConcurrencyStamp] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AspNetUsers] (
        [Id] nvarchar(450) NOT NULL,
        [UserName] nvarchar(256) NULL,
        [NormalizedUserName] nvarchar(256) NULL,
        [Email] nvarchar(256) NULL,
        [NormalizedEmail] nvarchar(256) NULL,
        [EmailConfirmed] bit NOT NULL,
        [PasswordHash] nvarchar(max) NULL,
        [SecurityStamp] nvarchar(max) NULL,
        [ConcurrencyStamp] nvarchar(max) NULL,
        [PhoneNumber] nvarchar(max) NULL,
        [PhoneNumberConfirmed] bit NOT NULL,
        [TwoFactorEnabled] bit NOT NULL,
        [LockoutEnd] datetimeoffset NULL,
        [LockoutEnabled] bit NOT NULL,
        [AccessFailedCount] int NOT NULL,
        [RequiresPasswordReset] bit NOT NULL,
        CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Billing_Pay] (
        [Id] int NOT NULL IDENTITY,
        [Amount] float NOT NULL,
        [Date_Of_Opreation] date NOT NULL,
        [Notes] nvarchar(max) NOT NULL,
        [Custmor_Id] int NOT NULL,
        CONSTRAINT [PK_Billing_Pay] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Billing_Pay_Customers] FOREIGN KEY ([Custmor_Id]) REFERENCES [Customers] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Billing_Receipt] (
        [Id] int NOT NULL IDENTITY,
        [Amount] float NOT NULL,
        [Date_Of_Opreation] date NOT NULL,
        [Notes] nvarchar(max) NOT NULL,
        [Employee_Id] int NOT NULL,
        CONSTRAINT [PK_Billing_Receipt] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Billing_Receipt_Customers] FOREIGN KEY ([Employee_Id]) REFERENCES [Customers] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Cases_Employees] (
        [Id] int NOT NULL IDENTITY,
        [Case_Code] int NOT NULL,
        [Employee_Id] int NOT NULL,
        CONSTRAINT [PK_Cases_Employees] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Cases_Employees_Employees] FOREIGN KEY ([Employee_Id]) REFERENCES [Employees] ([id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Cases_Files] (
        [Id] int NOT NULL IDENTITY,
        [Case_Id] int NOT NULL,
        [File_Id] int NOT NULL,
        CONSTRAINT [PK_Cases_Files] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Cases_Files_Cases] FOREIGN KEY ([Case_Id]) REFERENCES [Cases] ([Code]),
        CONSTRAINT [FK_Cases_Files_Files] FOREIGN KEY ([File_Id]) REFERENCES [Files] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [CaseStatusHistory] (
        [Id] int NOT NULL IDENTITY,
        [Case_Id] int NOT NULL,
        [OldStatus] int NOT NULL,
        [NewStatus] int NOT NULL,
        [ChangedBy] nvarchar(max) NULL,
        [ChangedAt] datetime NOT NULL,
        CONSTRAINT [PK_CaseStatusHistory] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CaseStatusHistory_Cases] FOREIGN KEY ([Case_Id]) REFERENCES [Cases] ([Code]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Consulations] (
        [Id] int NOT NULL IDENTITY,
        [Consultion_State] nvarchar(50) NOT NULL,
        [Type] nvarchar(50) NOT NULL,
        [Subject] nvarchar(50) NOT NULL,
        [Descraption] nvarchar(50) NOT NULL,
        [Feedback] nvarchar(50) NOT NULL,
        [Notes] nvarchar(50) NOT NULL,
        [Date_time] datetime NOT NULL,
        CONSTRAINT [PK_Consulations] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Consulations_Employee] (
        [Id] int NOT NULL IDENTITY,
        [Consl_ID] int NOT NULL,
        [Employee_Id] int NOT NULL,
        CONSTRAINT [PK_Consulations_Employee] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Consulations_Employee_Employees] FOREIGN KEY ([Employee_Id]) REFERENCES [Employees] ([id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Contenders] (
        [Id] int NOT NULL IDENTITY,
        [Full_Name] nvarchar(50) NOT NULL,
        [SSN] int NOT NULL,
        [BirthDate] date NOT NULL,
        [Type] bit NULL,
        CONSTRAINT [PK_Contenders] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Custmors_Cases] (
        [Id] int NOT NULL IDENTITY,
        [Case_Id] int NOT NULL,
        [Custmors_Id] int NOT NULL,
        CONSTRAINT [PK_Custmors_Cases] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Custmors_Cases_Cases] FOREIGN KEY ([Case_Id]) REFERENCES [Cases] ([Code]),
        CONSTRAINT [FK_Custmors_Cases_Customers] FOREIGN KEY ([Custmors_Id]) REFERENCES [Customers] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Governaments] (
        [Id] int NOT NULL,
        [Gov_Name] nvarchar(50) NOT NULL,
        CONSTRAINT [PK_Governaments] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Judicial_Documents] (
        [Id] int NOT NULL IDENTITY,
        [Doc_Type] nvarchar(50) NOT NULL,
        [Doc_Num] int NOT NULL,
        [Doc_Details] nvarchar(50) NOT NULL,
        [Notes] nvarchar(50) NOT NULL,
        [Num_Of_Agent] int NOT NULL,
        [Customers_Id] int NOT NULL,
        CONSTRAINT [PK_Judicial_Documents] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Judicial_Documents_Customers] FOREIGN KEY ([Customers_Id]) REFERENCES [Customers] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Sitings] (
        [Id] int NOT NULL IDENTITY,
        [Siting_Time] datetime NOT NULL,
        [Siting_Date] date NOT NULL,
        [Siting_Notification] datetime NOT NULL,
        [Judge_Name] nvarchar(50) NOT NULL,
        [Notes] nvarchar(50) NOT NULL,
        CONSTRAINT [PK_Sitings] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [App_Sitting] (
        [Id] int NOT NULL IDENTITY,
        [User_Id] int NOT NULL,
        [App_PageID] int NOT NULL,
        [IsVaild] bit NULL,
        CONSTRAINT [PK_App_Sitting] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_App_Sitting_App_Pages] FOREIGN KEY ([App_PageID]) REFERENCES [App_Pages] ([Id]),
        CONSTRAINT [FK_App_Sitting_Users] FOREIGN KEY ([User_Id]) REFERENCES [Users] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AspNetRoleClaims] (
        [Id] int NOT NULL IDENTITY,
        [RoleId] nvarchar(450) NOT NULL,
        [ClaimType] nvarchar(max) NULL,
        [ClaimValue] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AspNetUserClaims] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [ClaimType] nvarchar(max) NULL,
        [ClaimValue] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AspNetUserLogins] (
        [LoginProvider] nvarchar(450) NOT NULL,
        [ProviderKey] nvarchar(450) NOT NULL,
        [ProviderDisplayName] nvarchar(max) NULL,
        [UserId] nvarchar(450) NOT NULL,
        CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]),
        CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AspNetUserRoles] (
        [UserId] nvarchar(450) NOT NULL,
        [RoleId] nvarchar(450) NOT NULL,
        CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY ([UserId], [RoleId]),
        CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [AspNetUserTokens] (
        [UserId] nvarchar(450) NOT NULL,
        [LoginProvider] nvarchar(450) NOT NULL,
        [Name] nvarchar(450) NOT NULL,
        [Value] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
        CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Consltitions_Custmors] (
        [Id] int NOT NULL IDENTITY,
        [Customer_Id] int NOT NULL,
        [Consl_Id] int NOT NULL,
        CONSTRAINT [PK_Consltitions_Custmors] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Consltitions_Custmors_Consulations] FOREIGN KEY ([Consl_Id]) REFERENCES [Consulations] ([Id]),
        CONSTRAINT [FK_Consltitions_Custmors_Customers] FOREIGN KEY ([Customer_Id]) REFERENCES [Customers] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Cases_Contenders] (
        [Id] int NOT NULL IDENTITY,
        [Case_Id] int NOT NULL,
        [Contender_Id] int NOT NULL,
        CONSTRAINT [PK_Cases_Contenders] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Cases_Contenders_Cases] FOREIGN KEY ([Case_Id]) REFERENCES [Cases] ([Code]),
        CONSTRAINT [FK_Cases_Contenders_Contenders] FOREIGN KEY ([Contender_Id]) REFERENCES [Contenders] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Contenders_Lawyers] (
        [Id] int NOT NULL IDENTITY,
        [Contender_Id] int NOT NULL,
        CONSTRAINT [PK_Contenders_Lawyers] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Contenders_Lawyers_Contenders] FOREIGN KEY ([Contender_Id]) REFERENCES [Contenders] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Courts] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(50) NOT NULL,
        [Address] nvarchar(50) NOT NULL,
        [Telephone] nvarchar(50) NOT NULL,
        [Notes] nvarchar(50) NOT NULL,
        [Gov_Id] int NOT NULL,
        CONSTRAINT [PK_Courts] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Courts_Governaments] FOREIGN KEY ([Gov_Id]) REFERENCES [Governaments] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Cases_Sitings] (
        [Id] int NOT NULL IDENTITY,
        [Case_Code] int NOT NULL,
        [Siting_Id] int NOT NULL,
        CONSTRAINT [PK_Cases_Sitings] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Cases_Sitings_Cases] FOREIGN KEY ([Case_Code]) REFERENCES [Cases] ([Code]),
        CONSTRAINT [FK_Cases_Sitings_Sitings] FOREIGN KEY ([Siting_Id]) REFERENCES [Sitings] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Con_Lawyers_Custmors] (
        [Id] int NOT NULL IDENTITY,
        [Con_Custmor_Id] int NOT NULL,
        [Con_Lawyer_Id] int NOT NULL,
        CONSTRAINT [PK_Con_Lawyers_Custmors] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Con_Lawyers_Custmors_Contenders_Lawyers] FOREIGN KEY ([Con_Lawyer_Id]) REFERENCES [Contenders_Lawyers] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Contenders_Custmors] (
        [Id] int NOT NULL IDENTITY,
        [Con_Lawyer_ID] int NULL,
        [Con_Id] int NULL,
        CONSTRAINT [PK_Contenders_Custmors] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Contenders_Custmors_Contenders] FOREIGN KEY ([Con_Id]) REFERENCES [Contenders] ([Id]),
        CONSTRAINT [FK_Contenders_Custmors_Contenders_Lawyers] FOREIGN KEY ([Con_Lawyer_ID]) REFERENCES [Contenders_Lawyers] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE TABLE [Cases_Courts] (
        [Id] int NOT NULL IDENTITY,
        [Court_Id] int NOT NULL,
        [Case_Code] int NOT NULL,
        CONSTRAINT [PK_Cases_Courts] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Cases_Courts_Cases] FOREIGN KEY ([Case_Code]) REFERENCES [Cases] ([Code]),
        CONSTRAINT [FK_Cases_Courts_Courts] FOREIGN KEY ([Court_Id]) REFERENCES [Courts] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_AdminstrativeTasks_employee_Id] ON [AdminstrativeTasks] ([employee_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_App_Sitting_App_PageID] ON [App_Sitting] ([App_PageID]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_App_Sitting_User_Id] ON [App_Sitting] ([User_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [AspNetRoleClaims] ([RoleId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [RoleNameIndex] ON [AspNetRoles] ([NormalizedName]) WHERE ([NormalizedName] IS NOT NULL)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_AspNetUserClaims_UserId] ON [AspNetUserClaims] ([UserId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_AspNetUserLogins_UserId] ON [AspNetUserLogins] ([UserId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [AspNetUserRoles] ([RoleId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [EmailIndex] ON [AspNetUsers] ([NormalizedEmail]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UserNameIndex] ON [AspNetUsers] ([NormalizedUserName]) WHERE ([NormalizedUserName] IS NOT NULL)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Billing_Pay_Custmor_Id] ON [Billing_Pay] ([Custmor_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Billing_Receipt_Employee_Id] ON [Billing_Receipt] ([Employee_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Contenders_Case_Id] ON [Cases_Contenders] ([Case_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Contenders_Contender_Id] ON [Cases_Contenders] ([Contender_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Courts_Case_Code] ON [Cases_Courts] ([Case_Code]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Courts_Court_Id] ON [Cases_Courts] ([Court_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Employees_Employee_Id] ON [Cases_Employees] ([Employee_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Files_Case_Id] ON [Cases_Files] ([Case_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Files_File_Id] ON [Cases_Files] ([File_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Sitings_Case_Code] ON [Cases_Sitings] ([Case_Code]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Cases_Sitings_Siting_Id] ON [Cases_Sitings] ([Siting_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_CaseStatusHistory_Case_Id] ON [CaseStatusHistory] ([Case_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Con_Lawyers_Custmors_Con_Lawyer_Id] ON [Con_Lawyers_Custmors] ([Con_Lawyer_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Consltitions_Custmors_Consl_Id] ON [Consltitions_Custmors] ([Consl_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Consltitions_Custmors_Customer_Id] ON [Consltitions_Custmors] ([Customer_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Consulations_Employee_Employee_Id] ON [Consulations_Employee] ([Employee_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Contenders_Custmors_Con_Id] ON [Contenders_Custmors] ([Con_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Contenders_Custmors_Con_Lawyer_ID] ON [Contenders_Custmors] ([Con_Lawyer_ID]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Contenders_Lawyers_Contender_Id] ON [Contenders_Lawyers] ([Contender_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Courts_Gov_Id] ON [Courts] ([Gov_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Custmors_Cases_Case_Id] ON [Custmors_Cases] ([Case_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Custmors_Cases_Custmors_Id] ON [Custmors_Cases] ([Custmors_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    CREATE INDEX [IX_Judicial_Documents_Customers_Id] ON [Judicial_Documents] ([Customers_Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260216233119_AddCaseStatusAndHistory'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260216233119_AddCaseStatusAndHistory', N'8.0.0');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Users] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Sitings] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Judicial_Documents] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Governaments] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Files] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Employees] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Customers] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Custmors_Cases] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Courts] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Contenders_Lawyers] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Contenders_Custmors] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Contenders] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Consulations_Employee] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Consulations] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Consltitions_Custmors] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Con_Lawyers_Custmors] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [CaseStatusHistory] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Cases_Sitings] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Cases_Files] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Cases_Employees] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Cases_Courts] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Cases_Contenders] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Cases] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Billing_Receipt] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [Billing_Pay] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    ALTER TABLE [AdminstrativeTasks] ADD [FirmId] int NOT NULL DEFAULT 1;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE TABLE [AuditLogs] (
        [Id] bigint NOT NULL IDENTITY,
        [EntityName] nvarchar(128) NOT NULL,
        [Action] nvarchar(16) NOT NULL,
        [EntityId] nvarchar(256) NULL,
        [OldValues] nvarchar(max) NULL,
        [NewValues] nvarchar(max) NULL,
        [UserId] nvarchar(256) NULL,
        [UserName] nvarchar(256) NULL,
        [Timestamp] datetime2 NOT NULL,
        [RequestPath] nvarchar(512) NULL,
        [FirmId] int NOT NULL DEFAULT 1,
        CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Users_FirmId] ON [Users] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Sitings_FirmId] ON [Sitings] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Judicial_Documents_FirmId] ON [Judicial_Documents] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Governaments_FirmId] ON [Governaments] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Files_FirmId] ON [Files] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Employees_FirmId] ON [Employees] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Customers_FirmId] ON [Customers] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Custmors_Cases_FirmId] ON [Custmors_Cases] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Courts_FirmId] ON [Courts] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Contenders_Lawyers_FirmId] ON [Contenders_Lawyers] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Contenders_Custmors_FirmId] ON [Contenders_Custmors] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Contenders_FirmId] ON [Contenders] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Consulations_Employee_FirmId] ON [Consulations_Employee] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Consulations_FirmId] ON [Consulations] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Consltitions_Custmors_FirmId] ON [Consltitions_Custmors] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Con_Lawyers_Custmors_FirmId] ON [Con_Lawyers_Custmors] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_CaseStatusHistory_FirmId] ON [CaseStatusHistory] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Cases_Sitings_FirmId] ON [Cases_Sitings] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Cases_Files_FirmId] ON [Cases_Files] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Cases_Employees_FirmId] ON [Cases_Employees] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Cases_Courts_FirmId] ON [Cases_Courts] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Cases_Contenders_FirmId] ON [Cases_Contenders] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Cases_FirmId] ON [Cases] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Billing_Receipt_FirmId] ON [Billing_Receipt] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_Billing_Pay_FirmId] ON [Billing_Pay] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_AdminstrativeTasks_FirmId] ON [AdminstrativeTasks] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    CREATE INDEX [IX_AuditLogs_FirmId] ON [AuditLogs] ([FirmId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260217112706_AddPhase4MultiTenancyAuditAndStatus'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260217112706_AddPhase4MultiTenancyAuditAndStatus', N'8.0.0');
END;
GO

COMMIT;
GO

