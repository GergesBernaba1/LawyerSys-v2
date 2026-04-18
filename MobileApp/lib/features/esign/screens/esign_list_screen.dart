import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/esign_bloc.dart';
import '../bloc/esign_event.dart';
import '../bloc/esign_state.dart';
import '../models/esign_request.dart';

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
              title: const Text('New E-Sign Request'), // TODO: localize
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *', // TODO: localize
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Document content field
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Document Content', // TODO: localize
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Signer emails
                    const Text(
                      'Signers', // TODO: localize
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Enter email', // TODO: localize
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
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
                          child: const Text('Add'), // TODO: localize
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
                                ? 'Expiry Date (optional)' // TODO: localize
                                : 'Expires: ${_formatDate(expiresAt!)}',
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(expiresAt == null
                              ? 'Pick' // TODO: localize
                              : 'Change'), // TODO: localize
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
                  child: const Text('Cancel'), // TODO: localize
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
                  child: const Text('Submit'), // TODO: localize
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
    String selectedStatus = request.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Status'), // TODO: localize
              content: DropdownButtonFormField<String>(
                initialValue: _statusOptions.contains(selectedStatus)
                    ? selectedStatus
                    : _statusOptions.first,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Status', // TODO: localize
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
                  child: const Text('Cancel'), // TODO: localize
                ),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<ESignBloc>()
                        .add(UpdateESignStatus(request.id, selectedStatus));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Update'), // TODO: localize
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Signatures'), // TODO: localize
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status', // TODO: localize
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All'), // TODO: localize
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
        tooltip: 'New E-Sign Request', // TODO: localize
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
                content: Text('Error: ${state.message}'), // TODO: localize
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ESignShareLinkReady) {
            Clipboard.setData(ClipboardData(text: state.url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share link copied to clipboard'), // TODO: localize
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
                  Text('Error: ${state.message}'), // TODO: localize
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ESignBloc>()
                        .add(LoadESignRequests(status: _selectedStatus)),
                    child: const Text('Retry'), // TODO: localize
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
    // Show active filter chip if a filter is applied
    return Column(
      children: [
        if (_selectedStatus != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                const Text('Filtered by: '), // TODO: localize
                _buildStatusChip(_selectedStatus!),
                const Spacer(),
                TextButton(
                  onPressed: () => _applyFilter(null),
                  child: const Text('Clear'), // TODO: localize
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
                      const Text(
                        'No e-sign requests found', // TODO: localize
                        style: TextStyle(color: Colors.grey),
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
              '$signedCount / $totalSigners signer(s)', // TODO: localize
              style: const TextStyle(fontSize: 12),
            ),
            if (request.expiresAt != null)
              Text(
                'Expires: ${_formatDate(request.expiresAt!)}', // TODO: localize
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        isThreeLine: request.expiresAt != null,
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleTileAction(action, request),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share_link',
              child: ListTile(
                leading: Icon(Icons.link),
                title: Text('Get Share Link'), // TODO: localize
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'update_status',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Update Status'), // TODO: localize
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
    }
  }
}
