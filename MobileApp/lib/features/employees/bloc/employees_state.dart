import '../models/employee.dart';

abstract class EmployeesState {}

class EmployeesInitial extends EmployeesState {}

class EmployeesLoading extends EmployeesState {}

class EmployeesLoaded extends EmployeesState {
  final List<EmployeeModel> employees;
  EmployeesLoaded(this.employees);
}

class EmployeesError extends EmployeesState {
  final String message;
  EmployeesError(this.message);
}

class EmployeeDetailLoaded extends EmployeesState {
  final EmployeeModel employee;
  EmployeeDetailLoaded(this.employee);
}

class EmployeeOperationSuccess extends EmployeesState {
  final String message;
  EmployeeOperationSuccess(this.message);
}
