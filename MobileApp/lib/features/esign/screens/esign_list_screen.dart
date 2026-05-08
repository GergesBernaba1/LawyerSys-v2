import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/esign/bloc/esign_bloc.dart';
import 'package:qadaya_lawyersys/features/esign/bloc/esign_event.dart';
import 'package:qadaya_lawyersys/features/esign/bloc/esign_state.dart';
import 'package:qadaya_lawyersys/features/esign/models/esign_request.dart';

class ESignListScreen extends StatefulWidget {
  const ESignListScreen({super.key});

  @override
  State<ESignListScreen> createState() => _ESignListScreenState();
}

class _ESignListScreenState extends State<ESignListScreen> {
  String? _selectedStatus; // null = All

  static const List<String> _statusOptions = [
    'Pending',
    'Signed',
    'Rejected',
    'Expired',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ESignBloc>().add(LoadESignRequests());
  }

  void _applyFilter(String? status) {
    setState(() => _selectedStatus = status);
    context.read<ESignBloc>().add(LoadESignRequests(status: status));
  }

  // ---------------------------------------------------------------------------
  // Create dialog
  // ---------------------------------------------------------------------------

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final emailController = TextEditingController();
    final signerEmails = <String>[];
    DateTime? expiresAt;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.newESignRequest),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Document content field
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Signer emails
                    Text(
                      l10n.employees,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: l10n.email,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10,),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final email = emailController.text.trim();
                            if (email.isNotEmpty &&
                                !signerEmails.contains(email)) {
                              setDialogState(() {
                                signerEmails.add(email);
                                emailController.clear();
                              });
                            }
                          },
                          child: Text(l10n.add),
                        ),
                      ],
                    ),
                    if (signerEmails.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: signerEmails.map((email) {
                          return Chip(
                            label: Text(
                              email,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onDeleted: () {
                              setDialogState(() => signerEmails.remove(email));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Expiry date picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expiresAt == null
                                ? l10n.calendarEventEndOptional
                                : 'Expires: ${_formatDate(expiresAt!)}',
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(expiresAt == null
                              ? l10n.dateLabel
                              : l10n.edit,),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now()
                                  .add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => expiresAt = picked);
                            }
                          },
                        ),
                        if (expiresAt != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setDialogState(() => expiresAt = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    context.read<ESignBloc>().add(
                          CreateESignRequest(
                            title: title,
                            documentContent: contentController.text.trim(),
                            signerEmails: List.from(signerEmails),
                            expiresAt: expiresAt,
                          ),
                        );
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(l10n.submit),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Update status dialog
  // ---------------------------------------------------------------------------

  Future<void> _showUpdateStatusDialog(ESignRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    String selectedStatus = request.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.updateStatus),
              content: DropdownButtonFormField<String>(
                initialValue: _statusOptions.contains(selectedStatus)
                    ? selectedStatus
                    : _statusOptions.first,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.status,
                ),
                items: _statusOptions.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedStatus = val);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<ESignBloc>()
                        .add(UpdateESignStatus(request.id, selectedStatus));
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(l10n.update),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'signed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eSignatures),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.filteredBy,
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              PopupMenuItem<String?>(
                child: Text(l10n.all),
              ),
              ..._statusOptions.map(
                (s) => PopupMenuItem<String?>(value: s, child: Text(s)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: l10n.newESignRequest,
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ESignBloc, ESignState>(
        listener: (context, state) {
          if (state is ESignOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ESignError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.error}: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ESignShareLinkReady) {
            Clipboard.setData(ClipboardData(text: state.url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.shareLinkCopied),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ESignLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ESignError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ESignBloc>()
                        .add(LoadESignRequests(status: _selectedStatus)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state is ESignLoaded) {
            return _buildList(state.requests);
          }

          // ESignInitial or any other state — show empty/loading placeholder
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildList(List<ESignRequest> requests) {
    final l10n = AppLocalizations.of(context)!;
    // Show active filter chip if a filter is applied
    return Column(
      children: [
        if (_selectedStatus != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Text('${l10n.filteredBy}: '),
                _buildStatusChip(_selectedStatus!),
                const Spacer(),
                TextButton(
                  onPressed: () => _applyFilter(null),
                  child: Text(l10n.clear),
                ),
              ],
            ),
          ),
        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.draw, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noData,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestTile(requests[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestTile(ESignRequest request) {
    final l10n = AppLocalizations.of(context)!;
    final signedCount = request.signers.where((s) => s.hasSigned).length;
    final totalSigners = request.signers.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.draw_outlined, color: Colors.indigo),
        title: Row(
          children: [
            Expanded(
              child: Text(
                request.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(request.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '$signedCount / $totalSigners',
              style: const TextStyle(fontSize: 12),
            ),
            if (request.expiresAt != null)
              Text(
                '${l10n.calendarEventEnd}: ${_formatDate(request.expiresAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        isThreeLine: request.expiresAt != null,
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleTileAction(action, request),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share_link',
              child: ListTile(
                leading: const Icon(Icons.link),
                title: Text(l10n.getShareLink),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'update_status',
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.updateStatus),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (request.status != 'Cancelled')
              PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: Text(l10n.cancel,
                      style: const TextStyle(color: Colors.red),),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTileAction(String action, ESignRequest request) {
    switch (action) {
      case 'share_link':
        context.read<ESignBloc>().add(GetESignShareLink(request.id));
      case 'update_status':
        _showUpdateStatusDialog(request);
      case 'cancel':
        _confirmCancel(request);
    }
  }

  Future<void> _confirmCancel(ESignRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancel),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      context.read<ESignBloc>().add(UpdateESignStatus(request.id, 'Cancelled'));
    }
  }
}
