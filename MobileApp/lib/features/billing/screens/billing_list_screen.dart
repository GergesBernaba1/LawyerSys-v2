import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/billing_bloc.dart';
import '../bloc/billing_event.dart';
import '../bloc/billing_state.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/billing.dart';
import 'billing_form_screen.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  int _selectedTab = 0; // 0 for payments, 1 for receipts

  @override
  void initState() {
    super.initState();
    context.read<BillingBloc>().add(LoadPayments());
    context.read<BillingBloc>().add(LoadReceipts());
    context.read<BillingBloc>().add(LoadCustomers());
    context.read<BillingBloc>().add(LoadEmployees());
    context.read<BillingBloc>().add(LoadSummary());
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.billing)),
      body: BlocConsumer<BillingBloc, BillingState>(
        listener: (context, state) {
          if (state is BillingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizer.error}: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is BillingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BillingError) {
            return Center(child: Text('${localizer.error}: ${state.message}'));
          }
          if (state is BillingLoaded) {
            final payments = state.payments;
            final receipts = state.receipts;
            final customers = state.customers;
            final employees = state.employees;
            final summary = state.summary;

            return Column(
              children: [
                // Summary cards (only show for admins or if we want to show to everyone)
                if (summary != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                              localizer.payments, '\$${(summary.totalPayments ?? 0).toStringAsFixed(2)}', Colors.red),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                              localizer.receipts, '\$${(summary.totalReceipts ?? 0).toStringAsFixed(2)}', Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                              localizer.balance, '\$${(summary.balance ?? 0).toStringAsFixed(2)}',
                              (summary.balance ?? 0) >= 0 ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ),

                // Tabs
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _selectedTab = 0),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTab == 0
                                ? Theme.of(context).primaryColor
                                : null,
                            foregroundColor: _selectedTab == 0
                                ? Colors.white
                                : null,
                          ),
                          child: Text(localizer.payments),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _selectedTab = 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTab == 1
                                ? Theme.of(context).primaryColor
                                : null,
                            foregroundColor: _selectedTab == 1
                                ? Colors.white
                                : null,
                          ),
                          child: Text(localizer.receipts),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add button (only for admins)
                // In a real app, we'd check user roles here
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillingFormScreen(
                            isPayment: _selectedTab == 0,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(
                          _selectedTab == 0 ? localizer.payments : localizer.receipts),
                    ),
                  ),
                ),

                // Expanded list
                Expanded(
                  child: _selectedTab == 0
                      ? _buildPaymentsList(payments)
                      : _buildReceiptsList(receipts),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList(List<BillingPay> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(localizer.noPaymentsFound),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.payment, color: Colors.red),
            title: Text('\$${payment.amount.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${localizer.dateLabel}: ${payment.dateOfOperation}'),
                Text('${localizer.customer}: ${payment.customerName ?? payment.customerId}'),
                if (payment.notes.isNotEmpty)
                  Text('${localizer.notes}: ${payment.notes}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // In a real app, we'd show a confirmation dialog
                context
                    .read<BillingBloc>()
                    .add(DeletePayment(payment.id ?? 0));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptsList(List<BillingReceipt> receipts) {
    if (receipts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(localizer.noReceiptsFound),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
            title: Text('\$${receipt.amount.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${receipt.dateOfOperation}'),
                Text('Employee: ${receipt.employeeId}'),
                if (receipt.notes.isNotEmpty)
                  Text('Notes: ${receipt.notes}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // In a real app, we'd show a confirmation dialog
                context
                    .read<BillingBloc>()
                    .add(DeleteReceipt(receipt.id ?? 0));
              },
            ),
          ),
        );
      },
    );
  }
}