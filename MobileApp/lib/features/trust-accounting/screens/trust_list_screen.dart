import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../../authentication/models/user_session.dart';
import '../bloc/trust_accounting_bloc.dart';
import '../bloc/trust_accounting_event.dart';
import '../bloc/trust_accounting_state.dart';
import '../models/trust_transaction.dart';
import 'trust_form_screen.dart';

class TrustListScreen extends StatefulWidget {
  const TrustListScreen({super.key});

  @override
  State<TrustListScreen> createState() => _TrustListScreenState();
}

class _TrustListScreenState extends State<TrustListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TrustAccountingBloc>().add(LoadTrustTransactions());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    final canManage = session?.hasPermission(Permissions.createTrustAccounting) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.trustAccounting)),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TrustFormScreen()));
                context.read<TrustAccountingBloc>().add(RefreshTrustTransactions());
              },
              child: const Icon(Icons.add),
            )
          : null,
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
                  onPressed: () => context.read<TrustAccountingBloc>().add(SearchTrustTransactions(_searchController.text)),
                ),
              ),
              onSubmitted: (value) => context.read<TrustAccountingBloc>().add(SearchTrustTransactions(value)),
            ),
          ),
          Expanded(
            child: BlocConsumer<TrustAccountingBloc, TrustAccountingState>(
              listener: (context, state) {
                if (state is TrustAccountingError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizer.error}: ${state.message}')));
                }
                if (state is TrustTransactionOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is TrustAccountingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TrustAccountingError) {
                  return Center(child: Text('${localizer.error}: ${state.message}'));
                }
                if (state is TrustAccountingLoaded) {
                  final transactions = state.transactions;
                  if (transactions.isEmpty) {
                    return Center(child: Text(localizer.noData));
                  }
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return ListTile(
                        title: Text('${item.transactionType} - ${item.amount.toStringAsFixed(2)}'),
                        subtitle: Text('${item.caseId} • ${item.accountId} • ${item.status}'),
                        onTap: () => _showTransactionDetails(item, localizer),
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

  void _showTransactionDetails(TrustTransactionModel transaction, AppLocalizations localizer) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizer.trustTransaction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizer.transactionId}: ${transaction.transactionId}'),
            Text('${localizer.caseCode}: ${transaction.caseId}'),
            Text('${localizer.accountId}: ${transaction.accountId}'),
            Text('${localizer.transactionType}: ${transaction.transactionType}'),
            Text('${localizer.amount}: ${transaction.amount.toStringAsFixed(2)}'),
            Text('${localizer.status}: ${transaction.status}'),
            Text('${localizer.dateLabel}: ${transaction.date.toLocal().toIso8601String()}'),
            Text('${localizer.notes}: ${transaction.notes}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localizer.cancel)),
        ],
      ),
    );
  }
}
