import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/client_portal_bloc.dart';
import '../bloc/client_portal_event.dart';
import '../bloc/client_portal_state.dart';
import '../models/portal_message.dart';

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

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.portalDocuments ?? 'Client Documents')),
      body: BlocConsumer<ClientPortalBloc, ClientPortalState>(
        listener: (context, state) {
          if (state is ClientPortalError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizer.error}: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is ClientPortalLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ClientPortalError) {
            return Center(child: Text('${localizer.error}: ${state.message}'));
          }
          if (state is ClientPortalDocumentsLoaded) {
            final docs = state.documents;
            if (docs.isEmpty) {
              return Center(child: Text(localizer.noData ?? 'No documents'));
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return ListTile(
                  title: Text(doc.subject),
                  subtitle: Text('${doc.from} • ${doc.sentAt.toLocal().toIso8601String().split('T').first}'),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizer.downloadStarted ?? 'Download started')));
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
