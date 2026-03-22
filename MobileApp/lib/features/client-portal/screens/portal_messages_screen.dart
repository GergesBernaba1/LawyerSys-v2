import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/client_portal_bloc.dart';
import '../bloc/client_portal_event.dart';
import '../bloc/client_portal_state.dart';
import '../models/portal_message.dart';

class PortalMessagesScreen extends StatefulWidget {
  const PortalMessagesScreen({super.key});

  @override
  State<PortalMessagesScreen> createState() => _PortalMessagesScreenState();
}

class _PortalMessagesScreenState extends State<PortalMessagesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientPortalBloc>().add(LoadPortalMessages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectMessage(PortalMessageModel message) {
    context.read<ClientPortalBloc>().add(SelectPortalMessage(message));
    context.read<ClientPortalBloc>().add(MarkMessageAsRead(message.messageId));

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.subject),
        content: SingleChildScrollView(child: Text(message.body)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).cancel)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.portalMessages)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizer.search,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.read<ClientPortalBloc>().add(SearchPortalMessages(_searchController.text)),
                ),
              ),
              onSubmitted: (value) => context.read<ClientPortalBloc>().add(SearchPortalMessages(value)),
            ),
          ),
          Expanded(
            child: BlocConsumer<ClientPortalBloc, ClientPortalState>(
              listener: (context, state) {
                if (state is ClientPortalError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizer.error}: ${state.message}')));
                }
                if (state is PortalMessageMarkedAsRead) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizer.markedAsRead)));
                }
              },
              builder: (context, state) {
                if (state is ClientPortalLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ClientPortalError) {
                  return Center(child: Text('${localizer.error}: ${state.message}'));
                }
                if (state is ClientPortalMessagesLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return Center(child: Text(localizer.noData));
                  }
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ListTile(
                        title: Text(msg.subject),
                        subtitle: Text('${msg.from} • ${msg.sentAt.toLocal().toIso8601String().split('T').first}'),
                        trailing: msg.isRead ? null : const Icon(Icons.mark_email_unread, color: Colors.blue),
                        onTap: () => _selectMessage(msg),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
