# Database schema summary

This document summarizes the important tables and relationships discovered in the provided SQL script (source: original project). Use this to guide EF Core Database-First scaffolding and to validate mapping.

Core tables (high-level):
- Users: Id (PK), Full_Name, Address, Job, Phon_Number, Date_Of_Birth, SSN, User_Name, Password
- Customers: Id (PK), Users_Id (FK -> Users.Id)
- Employees: id (PK), Salary, Users_Id (FK -> Users.Id)
- Cases: Code (PK), Id (int?), Invitions_Statment, Invition_Type, Invition_Date, Total_Amount, Notes
- Contenders: Id (PK), Full_Name, SSN, BirthDate, Type
- Courts: Id (PK), Name, Address, Telephone, Notes, Gov_Id (FK -> Governaments.Id)
- Files: Id (PK), Path, Code, type
- Sitings: Id (PK), Siting_Time, Siting_Date, Siting_Notification, Judge_Name, Notes
- Consulations: Id (PK), Consultion_State, Type, Subject, Descraption, Feedback, Notes, Date_time
- Judicial_Documents: Id (PK), Doc_Type, Doc_Num, Doc_Details, Notes, Num_Of_Agent, Customers_Id (FK)

Join / relationship tables:
- Customers_Cases: Case_Id -> Cases.Code, Custmors_Id -> Customers.Id
- Cases_Contenders: Case_Id -> Cases.Code, Contender_Id -> Contenders.Id
- Cases_Courts: Court_Id -> Courts.Id, Case_Code -> Cases.Code
- Cases_Employees: Case_Code -> Cases.Code, Employee_Id -> Employees.id
- Cases_Files: Case_Id -> Cases.Code, File_Id -> Files.Id
- Cases_Sitings: Case_Code -> Cases.Code, Siting_Id -> Sitings.Id
- Con_Lawyers_Custmors, Contenders_Custmors, Contenders_Lawyers, Consltitions_Custmors, Consulations_Employee (various join tables for relationships between lawyers / contenders / customers / employees)

Accounting tables:
- Billing_Pay: Id, Amount, Date_Of_Opreation, Notes, Custmor_Id (FK -> Customers.Id)
- Billing_Receipt: Id, Amount, Date_Of_Opreation, Notes, Employee_Id (FK -> Customers.Id ???) -- verify mapping

Permissions / app support tables:
- App_Pages (Id, Page_Name)
- App_Sitting (Id, User_Id -> Users, App_PageID -> App_Pages, IsVaild)
- AdminstrativeTasks (Id, Task_Name, Type, Task_Date, Task_Reminder_Date, Notes, employee_Id -> Employees.id)

Notes / discrepancies to check when scaffolding:
- Some tables use non-standard PKs (e.g., Cases uses Code as PK); confirm intended PKs and data types.
- Billing_Receipt references Employee_Id -> Customers.Id in the script (verify if this was intended or a script mistake).
- Validate datatypes for phone/SSN (currently int) — consider using string in EF models to avoid precision/format issues.

Next step: run `dotnet ef dbcontext scaffold` against the SQL Server database to generate models (set `--schema` or `--table` flags if you want a subset), then inspect generated navigation properties and adjust where necessary.
