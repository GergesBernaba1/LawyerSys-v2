import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/bloc/trust_accounting_bloc.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/bloc/trust_accounting_event.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/bloc/trust_accounting_state.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/models/trust_transaction.dart';

class TrustLedgerScreen extends StatefulWidget {
  const TrustLedgerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  final int customerId;
  final String customerName;

  @override
  State<TrustLedgerScreen> createState() => _TrustLedgerScreenState();
}

class _TrustLedgerScreenState extends State<TrustLedgerScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<TrustAccountingBloc>()
        .add(LoadTrustLedger(widget.customerId));
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName.isNotEmpty
            ? widget.customerName
            : '${l.trustAccounting} #${widget.customerId}',),
      ),
      body: BlocBuilder<TrustAccountingBloc, TrustAccountingState>(
        builder: (context, state) {
          if (state is TrustAccountingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TrustAccountingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${l.error}: ${state.message}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<TrustAccountingBloc>()
                        .add(LoadTrustLedger(widget.customerId)),
                    child: Text(l.retry),
                  ),
                ],
              ),
            );
          }
          if (state is TrustLedgerLoaded) {
            if (state.entries.isEmpty) {
              return Center(child: Text(l.noData));
            }
            return _buildLedger(context, state.entries, l);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLedger(
      BuildContext context,
      List<TrustTransactionModel> entries,
      AppLocalizations l,) {
    final lastBalance = entries.isNotEmpty ? entries.last.runningBalance : null;

    return Column(
      children: [
        if (lastBalance != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  l.trustBalance,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  lastBalance.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: lastBalance >= 0 ? Colors.green[700] : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCredit = entry.transactionType.toLowerCase().contains('deposit') ||
                  entry.transactionType.toLowerCase().contains('credit');
              final amountColor = isCredit ? Colors.green[700] : Colors.red[700];
              final amountSign = isCredit ? '+' : '-';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.12),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isCredit ? Colors.green[700] : Colors.red[700],
                    size: 18,
                  ),
                ),
                title: Text(
                  entry.transactionType,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.description != null && entry.description!.isNotEmpty)
                      Text(
                        entry.description!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      _formatDate(entry.date),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                isThreeLine: entry.description != null && entry.description!.isNotEmpty,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountSign${entry.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                        fontSize: 14,
                      ),
                    ),
                    if (entry.runningBalance != null)
                      Text(
                        entry.runningBalance!.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
