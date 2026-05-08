import 'package:flutter/material.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/governments/models/government.dart';

const _kPrimary = Color(0xFF14345A);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class GovernmentDetailScreen extends StatelessWidget {

  const GovernmentDetailScreen({super.key, required this.government});
  final Government government;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(government.governorateName),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_city, color: _kPrimary, size: 40),
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.location_city_outlined,
                      label: AppLocalizations.of(context)!.governorateName,
                      value: government.governorateName,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: _kPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kTextSecondary,
                  ),
                ),
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
      ),
    );
  }
}
