import 'package:qadaya_lawyersys/features/employees/models/employee.dart';

abstract class EmployeesState {}

class EmployeesInitial extends EmployeesState {}

class EmployeesLoading extends EmployeesState {}

class EmployeesLoaded extends EmployeesState {
  EmployeesLoaded(this.employees);
  final List<EmployeeModel> employees;
}

class EmployeesError extends EmployeesState {
  EmployeesError(this.message);
  final String message;
}

class EmployeeDetailLoaded extends EmployeesState {
  EmployeeDetailLoaded(this.employee);
  final EmployeeModel employee;
}

class EmployeeOperationSuccess extends EmployeesState {
  EmployeeOperationSuccess(this.message);
  final String message;
}
