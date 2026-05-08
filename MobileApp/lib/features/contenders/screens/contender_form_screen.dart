import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_bloc.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_event.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_state.dart';
import 'package:qadaya_lawyersys/features/contenders/models/contender.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);

class ContenderFormScreen extends StatefulWidget {
  const ContenderFormScreen({super.key, this.contender});
  final ContenderModel? contender;

  @override
  State<ContenderFormScreen> createState() => _ContenderFormScreenState();
}

class _ContenderFormScreenState extends State<ContenderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ssnController = TextEditingController();

  DateTime? _birthDate;
  bool? _type; // true = Plaintiff, false = Defendant

  @override
  void initState() {
    super.initState();
    if (widget.contender != null) {
      final c = widget.contender!;
      _fullNameController.text = c.fullName;
      _ssnController.text = c.ssn;
      _birthDate = c.birthDate;
      _type = c.type;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ssnController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1985),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context)!;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.allFieldsAreRequired)),
      );
      return;
    }

    final contender = ContenderModel(
      contenderId: widget.contender?.contenderId ?? '',
      fullName: _fullNameController.text.trim(),
      ssn: _ssnController.text.trim(),
      birthDate: _birthDate,
      type: _type,
    );

    final bloc = context.read<ContendersBloc>();
    if (widget.contender == null) {
      bloc.add(CreateContender(contender));
    } else {
      bloc.add(UpdateContender(contender));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEdit = widget.contender != null;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return BlocListener<ContendersBloc, ContendersState>(
      listener: (context, state) {
        if (state is ContenderOperationSuccess) Navigator.pop(context);
        if (state is ContendersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.error}: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? l.edit : l.add),
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                _buildField(
                  child: TextFormField(
                    controller: _fullNameController,
                    decoration: _inputDecoration(l.fullName, Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l.allFieldsAreRequired : null,
                  ),
                ),
                const SizedBox(height: 16),

                // SSN
                _buildField(
                  child: TextFormField(
                    controller: _ssnController,
                    decoration: _inputDecoration(l.ssn, Icons.badge_outlined),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l.allFieldsAreRequired : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Birth Date
                _buildField(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _inputDecoration(l.dateOfBirth, Icons.cake_outlined),
                      child: Text(
                        _birthDate != null
                            ? dateFormat.format(_birthDate!)
                            : l.dateOfBirth,
                        style: TextStyle(
                          fontSize: 16,
                          color: _birthDate != null ? const Color(0xFF0F172A) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Type dropdown
                _buildField(
                  child: DropdownButtonFormField<bool?>(
                    initialValue: _type,
                    decoration: _inputDecoration(l.caseType, Icons.gavel_outlined),
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: Text(l.plaintiff),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text(l.defendant),
                      ),
                    ],
                    onChanged: (v) => setState(() => _type = v),
                    hint: Text(l.caseType),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEdit ? l.save : l.create,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required Widget child}) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kPrimaryLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
