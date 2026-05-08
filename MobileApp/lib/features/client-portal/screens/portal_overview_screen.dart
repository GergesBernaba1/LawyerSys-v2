import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/client-portal/bloc/client_portal_bloc.dart';
import 'package:qadaya_lawyersys/features/client-portal/bloc/client_portal_event.dart';
import 'package:qadaya_lawyersys/features/client-portal/bloc/client_portal_state.dart';
import 'package:qadaya_lawyersys/features/client-portal/screens/portal_documents_screen.dart';
import 'package:qadaya_lawyersys/features/client-portal/screens/portal_messages_screen.dart';

class PortalOverviewScreen extends StatefulWidget {
  const PortalOverviewScreen({super.key});

  @override
  State<PortalOverviewScreen> createState() => _PortalOverviewScreenState();
}

class _PortalOverviewScreenState extends State<PortalOverviewScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClientPortalBloc>().add(LoadPortalOverview());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.clientPortal),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ClientPortalBloc>().add(LoadPortalOverview()),
          ),
        ],
      ),
      body: BlocBuilder<ClientPortalBloc, ClientPortalState>(
        builder: (context, state) {
          if (state is ClientPortalLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ClientPortalError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('${l.error}: ${state.message}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ClientPortalBloc>()
                        .add(LoadPortalOverview()),
                    child: Text(l.retry),
                  ),
                ],
              ),
            );
          }
          if (state is PortalOverviewLoaded) {
            return _buildOverview(context, state.data, l);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOverview(
      BuildContext context, Map<String, dynamic> data, AppLocalizations l,) {
    final unreadMessages = data['unreadMessages'] as int? ?? 0;
    final totalMessages = data['totalMessages'] as int? ?? 0;
    final totalDocuments = data['totalDocuments'] as int? ?? 0;
    final pendingDocuments = data['pendingDocuments'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.overview,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.mail_outline,
                  label: l.portalMessages,
                  value: totalMessages.toString(),
                  badge: unreadMessages > 0 ? unreadMessages.toString() : null,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.folder_shared,
                  label: l.portalDocuments,
                  value: totalDocuments.toString(),
                  badge: pendingDocuments > 0 ? pendingDocuments.toString() : null,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            l.quickAccess,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _QuickAccessTile(
            icon: Icons.mail_outline,
            title: l.portalMessages,
            subtitle: unreadMessages > 0
                ? '$unreadMessages ${l.unread}'
                : l.noData,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const PortalMessagesScreen(),),
            ),
          ),
          _QuickAccessTile(
            icon: Icons.folder_shared,
            title: l.portalDocuments,
            subtitle: '$totalDocuments ${l.documents}',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const PortalDocumentsScreen(),),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
