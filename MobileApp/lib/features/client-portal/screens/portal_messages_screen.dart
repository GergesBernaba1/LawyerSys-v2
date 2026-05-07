import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/client-portal/bloc/client_portal_bloc.dart';
import 'package:qadaya_lawyersys/features/client-portal/bloc/client_portal_event.dart';
import 'package:qadaya_lawyersys/features/client-portal/bloc/client_portal_state.dart';
import 'package:qadaya_lawyersys/features/client-portal/models/portal_message.dart';

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

  void _viewMessage(PortalMessageModel message, AppLocalizations l) {
    context.read<ClientPortalBloc>().add(SelectPortalMessage(message));
    context.read<ClientPortalBloc>().add(MarkMessageAsRead(message.messageId));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message.subject),
        content: SingleChildScrollView(child: Text(message.body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showComposeDialog(l, replySubject: 'Re: ${message.subject}');
            },
            child: Text(l.replyMessage),
          ),
        ],
      ),
    );
  }

  void _showComposeDialog(AppLocalizations l, {String replySubject = ''}) {
    final subjectCtrl = TextEditingController(text: replySubject);
    final bodyCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.replyMessage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: InputDecoration(
                labelText: l.consultationSubject,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l.messageBody,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final subject = subjectCtrl.text.trim();
              final body = bodyCtrl.text.trim();
              if (subject.isEmpty || body.isEmpty) return;
              context.read<ClientPortalBloc>().add(
                    SendPortalMessage(subject: subject, body: body),
                  );
              Navigator.pop(ctx);
            },
            child: Text(l.sendMessage),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.portalMessages)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.sendMessage,
        onPressed: () => _showComposeDialog(l),
        child: const Icon(Icons.edit),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.search,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context
                      .read<ClientPortalBloc>()
                      .add(SearchPortalMessages(_searchController.text)),
                ),
              ),
              onSubmitted: (v) => context
                  .read<ClientPortalBloc>()
                  .add(SearchPortalMessages(v)),
            ),
          ),
          Expanded(
            child: BlocConsumer<ClientPortalBloc, ClientPortalState>(
              listener: (context, state) {
                if (state is ClientPortalError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l.error}: ${state.message}')),);
                }
                if (state is PortalMessageMarkedAsRead) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.markedAsRead)));
                }
                if (state is PortalMessageSent) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.messageSent)));
                }
              },
              builder: (context, state) {
                if (state is ClientPortalLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ClientPortalError) {
                  return Center(
                      child: Text('${l.error}: ${state.message}'),);
                }
                if (state is ClientPortalMessagesLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return Center(child: Text(l.noDataAvailable));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context
                        .read<ClientPortalBloc>()
                        .add(RefreshPortalMessages()),
                    child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ListTile(
                          leading: Icon(
                            msg.isRead
                                ? Icons.mark_email_read
                                : Icons.mark_email_unread,
                            color: msg.isRead ? Colors.grey : Colors.blue,
                          ),
                          title: Text(msg.subject,
                              style: TextStyle(
                                  fontWeight: msg.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,),),
                          subtitle: Text(
                              '${msg.from} • ${msg.sentAt.toLocal().toIso8601String().split('T').first}',),
                          onTap: () => _viewMessage(msg, l),
                        );
                      },
                    ),
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
