import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/case_conversation_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/case_conversation_event.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/case_conversation_state.dart';
import 'package:qadaya_lawyersys/features/cases/repositories/case_conversation_repository.dart';

class CaseConversationScreen extends StatelessWidget {
  const CaseConversationScreen({
    super.key,
    required this.caseCode,
  });

  final String caseCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CaseConversationBloc(
        repository: CaseConversationRepository(ApiClient()),
      )..add(LoadCaseConversation(caseCode)),
      child: _CaseConversationBody(caseCode: caseCode),
    );
  }
}

class _CaseConversationBody extends StatefulWidget {
  const _CaseConversationBody({required this.caseCode});
  final String caseCode;

  @override
  State<_CaseConversationBody> createState() => _CaseConversationBodyState();
}

class _CaseConversationBodyState extends State<_CaseConversationBody> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _visibleToCustomer = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session =
        authState is AuthAuthenticated ? authState.session : null;
    final canSend = session?.hasPermission(Permissions.viewCases) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.caseConversation),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<CaseConversationBloc>()
                .add(LoadCaseConversation(widget.caseCode)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<CaseConversationBloc, CaseConversationState>(
              listener: (context, state) {
                if (state is CaseConversationLoaded) _scrollToBottom();
                if (state is CaseConversationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l.error}: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                if (state is CaseMessageSent) {
                  _messageCtrl.clear();
                  context
                      .read<CaseConversationBloc>()
                      .add(LoadCaseConversation(widget.caseCode));
                }
              },
              builder: (context, state) {
                if (state is CaseConversationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CaseConversationLoaded) {
                  if (state.messages.isEmpty) {
                    return Center(child: Text(l.noCaseConversation));
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8,),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isOwn = msg['senderUserId']?.toString() ==
                          session?.userId;
                      return _MessageBubble(
                        message: msg,
                        isOwn: isOwn,
                        session: session,
                      );
                    },
                  );
                }
                if (state is CaseConversationError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          if (canSend) _buildInputBar(context, l),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _visibleToCustomer,
                onChanged: (v) =>
                    setState(() => _visibleToCustomer = v ?? false),
              ),
              Text(l.visibleToCustomer,
                  style: Theme.of(context).textTheme.bodySmall,),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l.typeMessage,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8,),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BlocBuilder<CaseConversationBloc, CaseConversationState>(
                builder: (context, state) {
                  final sending = state is CaseConversationSending;
                  return IconButton.filled(
                    icon: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,),
                          )
                        : const Icon(Icons.send),
                    onPressed: sending
                        ? null
                        : () {
                            final text = _messageCtrl.text.trim();
                            if (text.isEmpty) return;
                            context.read<CaseConversationBloc>().add(
                                  SendCaseMessage(
                                    caseCode: widget.caseCode,
                                    message: text,
                                    visibleToCustomer: _visibleToCustomer,
                                  ),
                                );
                          },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.session,
  });

  final Map<String, dynamic> message;
  final bool isOwn;
  final UserSession? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final senderName =
        message['senderFullName']?.toString() ?? message['senderName']?.toString() ?? '?';
    final text = message['message']?.toString() ?? '';
    final visibleToCustomer = message['visibleToCustomer'] as bool? ?? false;
    final rawDate = message['createdAt']?.toString() ?? message['sentAt']?.toString() ?? '';
    final date = DateTime.tryParse(rawDate)?.toLocal();
    final timeStr = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Card(
          color: isOwn
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOwn)
                  Text(
                    senderName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(text),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    if (visibleToCustomer) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.visibility,
                          size: 12, color: theme.colorScheme.outline,),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
