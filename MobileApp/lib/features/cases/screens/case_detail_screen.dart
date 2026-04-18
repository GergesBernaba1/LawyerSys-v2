import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../../authentication/models/user_session.dart';
import '../bloc/cases_bloc.dart';
import '../bloc/cases_event.dart';
import '../models/case.dart';
import 'case_form_screen.dart';

class CaseDetailScreen extends StatelessWidget {
  final CaseModel caseModel;

  const CaseDetailScreen({super.key, required this.caseModel});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizer.caseDetail} ${caseModel.caseNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.pushNamed(context, '/documents');
            },
          ),
          if (session?.hasPermission(Permissions.editCases) ?? false)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CaseFormScreen(caseModel: caseModel)));
                if (context.mounted) {
                  context.read<CasesBloc>().add(RefreshCases());
                  context.read<CasesBloc>().add(SelectCase(caseModel.caseId));
                }
              },
            ),
          if (session?.hasPermission(Permissions.deleteCases) ?? false)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(localizer.deleteCase),
                    content: Text(localizer.deleteConfirm),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(localizer.cancel)),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(localizer.delete)),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<CasesBloc>().add(DeleteCase(caseModel.caseId));
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('${localizer.caseNumber}: ${caseModel.caseNumber}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('${localizer.status}: ${caseModel.caseStatus}'),
            Text('${localizer.caseType}: ${caseModel.caseType}'),
            Text('Code: ${caseModel.code}'),
            const SizedBox(height: 8),
            Text(
                '${localizer.filingDate}: ${caseModel.filingDate?.toLocal().toString() ?? 'N/A'}'),
            Text('${localizer.amount}: ${caseModel.totalAmount}'),
            if (caseModel.invitionsStatment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Statement: ${caseModel.invitionsStatment}'),
            ],
            if (caseModel.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${localizer.notes}: ${caseModel.notes}'),
            ],
            const SizedBox(height: 16),
            if (caseModel.assignedEmployees.isNotEmpty) ...[
              Text(localizer.assignedEmployees,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              ...caseModel.assignedEmployees.map((employee) => ListTile(
                    title: Text(employee.employeeName),
                    subtitle: Text(employee.role),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
