USE [master];
GO

IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'dbt')
BEGIN
    CREATE LOGIN [dbt] WITH PASSWORD = '123Administrator', CHECK_POLICY = OFF;
    ALTER SERVER ROLE [sysadmin] ADD MEMBER [dbt];
END
GO

IF DB_ID('dbt_artifact_integrationtests') IS NOT NULL
BEGIN
    ALTER DATABASE [dbt_artifact_integrationtests] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [dbt_artifact_integrationtests];
END
GO

CREATE DATABASE [dbt_artifact_integrationtests];
GO

USE [dbt_artifact_integrationtests];
GO

IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'dbt')
BEGIN
    CREATE LOGIN [dbt] WITH PASSWORD = '123Administrator', CHECK_POLICY = OFF;
    ALTER SERVER ROLE [sysadmin] ADD MEMBER [dbt];
END
GO
