import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_bloc.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_event.dart';
import 'package:qadaya_lawyersys/features/contenders/models/contender.dart';
import 'package:qadaya_lawyersys/features/contenders/screens/contender_form_screen.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class ContenderDetailScreen extends StatelessWidget {
  const ContenderDetailScreen({super.key, required this.contender});
  final ContenderModel contender;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPlaintiff = contender.type ?? false;
    final typeLabel = contender.type == null
        ? '—'
        : (isPlaintiff ? l.plaintiff : l.defendant);
    final typeColor =
        isPlaintiff ? const Color(0xFF1565C0) : const Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: Text(contender.fullName),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l.edit,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ContenderFormScreen(contender: contender),
                ),
              );
              if (context.mounted) {
                context.read<ContendersBloc>().add(RefreshContenders());
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kPrimaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      contender.fullName.isNotEmpty
                          ? contender.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    contender.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: l.ssn,
                      value: contender.ssn.isNotEmpty ? contender.ssn : '—',
                    ),
                    if (contender.birthDate != null) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        label: l.dateOfBirth,
                        value: DateFormat('yyyy-MM-dd').format(contender.birthDate!),
                      ),
                    ],
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.gavel_outlined,
                      label: l.caseType,
                      value: typeLabel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kPrimaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: _kTextSecondary),),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
