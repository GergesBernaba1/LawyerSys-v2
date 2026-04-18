import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/client_portal_bloc.dart';
import '../bloc/client_portal_event.dart';
import '../bloc/client_portal_state.dart';

class PortalDocumentsScreen extends StatefulWidget {
  const PortalDocumentsScreen({super.key});

  @override
  State<PortalDocumentsScreen> createState() => _PortalDocumentsScreenState();
}

class _PortalDocumentsScreenState extends State<PortalDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClientPortalBloc>().add(LoadPortalDocuments());
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: cannot open URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.portalDocuments)),
      body: BlocConsumer<ClientPortalBloc, ClientPortalState>(
        listener: (context, state) {
          if (state is ClientPortalError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.error}: ${state.message}')));
          }
          if (state is PortalDocumentUrlReady) {
            _openUrl(state.url);
          }
        },
        builder: (context, state) {
          if (state is ClientPortalLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ClientPortalError) {
            return Center(child: Text('${l.error}: ${state.message}'));
          }
          if (state is ClientPortalDocumentsLoaded) {
            final docs = state.documents;
            if (docs.isEmpty) {
              return Center(child: Text(l.noDataAvailable));
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<ClientPortalBloc>().add(RefreshPortalDocuments()),
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(doc.subject),
                    subtitle: Text(
                        '${doc.from} • ${doc.sentAt.toLocal().toIso8601String().split('T').first}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: l.downloadStarted,
                      onPressed: () => context
                          .read<ClientPortalBloc>()
                          .add(DownloadPortalDocument(doc.messageId)),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
