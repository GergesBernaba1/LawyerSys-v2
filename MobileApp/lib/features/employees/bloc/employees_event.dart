import '../models/employee.dart';

abstract class EmployeesEvent {}

class LoadEmployees extends EmployeesEvent {}

class RefreshEmployees extends EmployeesEvent {}

class SearchEmployees extends EmployeesEvent {
  final String query;

  SearchEmployees(this.query);
}

class SelectEmployee extends EmployeesEvent {
  final int employeeId;

  SelectEmployee(this.employeeId);
}

class CreateEmployee extends EmployeesEvent {
  final EmployeeModel employee;

  CreateEmployee(this.employee);
}

class UpdateEmployee extends EmployeesEvent {
  final EmployeeModel employee;

  UpdateEmployee(this.employee);
}

class DeleteEmployee extends EmployeesEvent {
  final int employeeId;

  DeleteEmployee(this.employeeId);
}
