import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/employees_repository.dart';
import 'employees_event.dart';
import 'employees_state.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  final EmployeesRepository employeesRepository;

  EmployeesBloc({required this.employeesRepository})
      : super(EmployeesInitial()) {
    on<LoadEmployees>(_onLoadEmployees);
    on<RefreshEmployees>(_onRefreshEmployees);
    on<SearchEmployees>(_onSearchEmployees);
    on<SelectEmployee>(_onSelectEmployee);
    on<CreateEmployee>(_onCreateEmployee);
    on<UpdateEmployee>(_onUpdateEmployee);
    on<DeleteEmployee>(_onDeleteEmployee);
  }

  Future<void> _onLoadEmployees(LoadEmployees event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      final employees = await employeesRepository.getEmployees();
      emit(EmployeesLoaded(employees));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }

  Future<void> _onRefreshEmployees(RefreshEmployees event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      final employees = await employeesRepository.getEmployees();
      emit(EmployeesLoaded(employees));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }

  Future<void> _onSearchEmployees(SearchEmployees event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      final employees = await employeesRepository.searchEmployees(event.query);
      emit(EmployeesLoaded(employees));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }

  Future<void> _onSelectEmployee(SelectEmployee event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      final employee = await employeesRepository.getEmployeeById(event.employeeId);
      if (employee == null) throw StateError('Employee not found');
      emit(EmployeeDetailLoaded(employee));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }

  Future<void> _onCreateEmployee(CreateEmployee event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      await employeesRepository.createEmployee(event.employee);
      emit(EmployeeOperationSuccess('Employee created successfully'));
      // Reload the list after successful creation
      final employees = await employeesRepository.getEmployees();
      emit(EmployeesLoaded(employees));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }

  Future<void> _onUpdateEmployee(UpdateEmployee event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      await employeesRepository.updateEmployee(event.employee);
      emit(EmployeeOperationSuccess('Employee updated successfully'));
      // Reload the list after successful update
      final employees = await employeesRepository.getEmployees();
      emit(EmployeesLoaded(employees));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }

  Future<void> _onDeleteEmployee(DeleteEmployee event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      await employeesRepository.deleteEmployee(event.employeeId);
      emit(EmployeeOperationSuccess('Employee deleted successfully'));
      // Reload the list after successful deletion
      final employees = await employeesRepository.getEmployees();
      emit(EmployeesLoaded(employees));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }
}