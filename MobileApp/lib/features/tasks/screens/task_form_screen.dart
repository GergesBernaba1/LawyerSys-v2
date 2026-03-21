import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import '../models/task.dart';
import '../../core/localization/app_localizations.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // If provided, we're editing; if null, we're creating

  const TaskFormScreen({
    super.key,
    this.task,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _typeController = TextEditingController();
  final _taskDateController = TextEditingController();
  final _taskReminderDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _employeeIdController = TextEditingController();

  bool _isLoading = false;
  bool _isEmployeeOnly = false; // This would come from auth state in a real app

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      // Populate form with existing task data for editing
      _taskNameController.text = widget.task!.taskName;
      _typeController.text = widget.task!.type;
      _taskDateController.text = widget.task!.taskDate?.split('T')[0] ?? '';
      _taskReminderDateController.text =
          widget.task!.taskReminderDate?.split('T')[0] ?? '';
      _notesController.text = widget.task!.notes ?? '';
      _employeeIdController.text = widget.task!.employeeId?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _typeController.dispose();
    _taskDateController.dispose();
    _taskReminderDateController.dispose();
    _notesController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final task = Task(
        id: widget.task?.id,
        taskName: _taskNameController.text.trim(),
        type: _typeController.text.trim(),
        taskDate: _taskDateController.text.isEmpty
            ? null
            : '${_taskDateController.text}T00:00:00',
        taskReminderDate: _taskReminderDateController.text.isEmpty
            ? null
            : '${_taskReminderDateController.text}T00:00:00',
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        employeeId: _employeeIdController.text.isEmpty
            ? null
            : int.tryParse(_employeeIdController.text),
      );

      if (widget.task == null) {
        // Creating new task
        context.read<TasksBloc>().add(AddTask(task));
      } else {
        // Updating existing task
        context.read<TasksBloc>().add(UpdateTask(task));
      }

      // Navigate back to tasks list
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations();
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? localizer.editTask : localizer.createTask),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _taskNameController,
                      decoration: InputDecoration(
                        labelText: localizer.taskName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizer.pleaseEnterTaskName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _typeController,
                      decoration: InputDecoration(
                        labelText: localizer.taskType,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizer.pleaseEnterTaskType;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taskDateController,
                      decoration: InputDecoration(
                        labelText: localizer.startDate,
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _taskDateController.text =
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taskReminderDateController,
                      decoration: InputDecoration(
                        labelText: localizer.reminderDate,
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _taskReminderDateController.text =
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!_isEmployeeOnly) ...[
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: InputDecoration(
                          labelText: localizer.assignedEmployee,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: localizer.notes,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEdit ? localizer.save : localizer.create),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}