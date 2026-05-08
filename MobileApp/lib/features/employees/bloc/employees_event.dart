import 'package:qadaya_lawyersys/features/employees/models/employee.dart';

abstract class EmployeesEvent {}

class LoadEmployees extends EmployeesEvent {}

class RefreshEmployees extends EmployeesEvent {}

class SearchEmployees extends EmployeesEvent {

  SearchEmployees(this.query);
  final String query;
}

class SelectEmployee extends EmployeesEvent {

  SelectEmployee(this.employeeId);
  final int employeeId;
}

class CreateEmployee extends EmployeesEvent {

  CreateEmployee(this.employee);
  final EmployeeModel employee;
}

class UpdateEmployee extends EmployeesEvent {

  UpdateEmployee(this.employee);
  final EmployeeModel employee;
}

class DeleteEmployee extends EmployeesEvent {

  DeleteEmployee(this.employeeId);
  final int employeeId;
}

class CreateEmployeeWithUser extends EmployeesEvent {
  CreateEmployeeWithUser(this.payload);
  final Map<String, dynamic> payload;
}
