import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.aboutUs),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // App icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel, color: _kPrimary, size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              'Qadaya LawyerSys',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${l.appVersion} 1.0.0',
              style: const TextStyle(
                fontSize: 14,
                color: _kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // ── About description card ──
            _InfoCard(
              icon: Icons.info_outline,
              title: l.aboutSection,
              child: Text(
                l.aboutAppDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: _kText,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Developer card ──
            _InfoCard(
              icon: Icons.code_outlined,
              title: l.developedBy,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerges Beranab Youssef',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'جرجس برنابا يوسف',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Contact info card ──
            _InfoCard(
              icon: Icons.contact_mail_outlined,
              title: l.contactInformation,
              child: Column(
                children: [
                  _ContactRow(
                    icon: Icons.email_outlined,
                    label: l.emailAddress,
                    value: 'support@qadaya.com',
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    label: l.phoneNumber,
                    value: '01284612434',
                    copyable: true,
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: Icons.chat_outlined,
                    label: l.whatsApp,
                    value: '01284612434',
                    copyable: true,
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: Icons.language_outlined,
                    label: l.website,
                    value: 'www.qadaya.com',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              l.copyrightNotice,
              style: TextStyle(
                fontSize: 12,
                color: _kTextSecondary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _kPrimaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18, color: _kPrimaryLight),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(),
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label: $value'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
      ],
    );
  }
}
