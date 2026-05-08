import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/bloc/trust_accounting_bloc.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/bloc/trust_accounting_event.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/bloc/trust_accounting_state.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/screens/trust_form_screen.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/screens/trust_ledger_screen.dart';

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
    final localizer = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    final canManage = session?.hasPermission(Permissions.createTrustAccounting) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.trustAccounting)),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final bloc = context.read<TrustAccountingBloc>();
                await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const TrustFormScreen()));
                if (mounted) bloc.add(RefreshTrustTransactions());
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
                      final customerName = item.customerName ?? item.accountId;
                      final customerId = int.tryParse(item.accountId) ?? 0;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            customerName.isNotEmpty
                                ? customerName[0].toUpperCase()
                                : '#',
                          ),
                        ),
                        title: Text(
                          customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${localizer.trustBalance}: ${item.amount.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TrustLedgerScreen(
                              customerId: customerId,
                              customerName: customerName,
                            ),
                          ),
                        ),
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
