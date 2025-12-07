-- Original DB creation script from the existing project
-- (Trimmed header for readability)
USE [master]
GO
CREATE DATABASE [LawyerSys]
CONTAINMENT = NONE
ON  PRIMARY 
( NAME = N'LawyerSys', FILENAME = N'E:\UC Barkely Cource\LawyerSys\DB\LawyerSys.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
LOG ON 
( NAME = N'LawyerSys_log', FILENAME = N'E:\UC Barkely Cource\LawyerSys\DB\LawyerSys_log.ldf' , SIZE = 2048KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
-- Script includes table definitions for:
-- AdminstrativeTasks, App_Pages, App_Sitting, Billing_Pay, Billing_Receipt,
-- Cases and related join tables (Cases_Contenders, Cases_Courts, Cases_Employees, Cases_Files, Cases_Sitings)
-- Con_Lawyers_Custmors, Consltitions_Custmors, Consulations, Consulations_Employee,
-- Contenders, Contenders_Custmors, Contenders_Lawyers, Courts, Custmors_Cases,
-- Customers, Employees, Files, Governaments, Judicial_Documents, Sitings, Users

-- (Full table and FK definitions omitted here — keep the original script around in the workspace.)

-- If you need the full original dump uncomment the rest of the full script or use the original file in the project root.
