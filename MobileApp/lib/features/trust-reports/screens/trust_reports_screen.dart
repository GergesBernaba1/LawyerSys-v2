import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/trust-reports/bloc/trust_reports_bloc.dart';
import 'package:qadaya_lawyersys/features/trust-reports/bloc/trust_reports_event.dart';
import 'package:qadaya_lawyersys/features/trust-reports/bloc/trust_reports_state.dart';
import 'package:qadaya_lawyersys/features/trust-reports/models/trust_report_models.dart';

class TrustReportsScreen extends StatefulWidget {
  const TrustReportsScreen({super.key});

  @override
  State<TrustReportsScreen> createState() => _TrustReportsScreenState();
}

class _TrustReportsScreenState extends State<TrustReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load initial financial summary (no filters)
    context.read<TrustReportsBloc>().add(LoadFinancialSummary());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      context.read<TrustReportsBloc>().add(LoadOutstandingBalances());
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Financial Summary'),
            Tab(text: 'Outstanding Balances'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FinancialSummaryTab(),
          _OutstandingBalancesTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 – Financial Summary
// ---------------------------------------------------------------------------

class _FinancialSummaryTab extends StatefulWidget {
  const _FinancialSummaryTab();

  @override
  State<_FinancialSummaryTab> createState() => _FinancialSummaryTabState();
}

class _FinancialSummaryTabState extends State<_FinancialSummaryTab> {
  int? _selectedYear;
  int? _selectedMonth; // null = "All"

  static const int _minYear = 2020;
  static const int _maxYear = 2027;

  void _dispatchLoad() {
    context.read<TrustReportsBloc>().add(LoadFinancialSummary(
          year: _selectedYear,
          month: _selectedMonth,
        ),);
  }

  Future<void> _onRefresh() async {
    _dispatchLoad();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrustReportsBloc, TrustReportsState>(
      listener: (context, state) {
        if (state is TrustReportsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Year / Month picker row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.year,
                        border: const OutlineInputBorder(),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      initialValue: _selectedYear,
                      items: [
                        DropdownMenuItem<int?>(
                          child: Text(AppLocalizations.of(context)!.all),
                        ),
                        for (int y = _maxYear; y >= _minYear; y--)
                          DropdownMenuItem<int?>(
                            value: y,
                            child: Text('$y'),
                          ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedYear = val);
                        _dispatchLoad();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.month,
                        border: const OutlineInputBorder(),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      initialValue: _selectedMonth,
                      items: [
                        DropdownMenuItem<int?>(
                          child: Text(AppLocalizations.of(context)!.all),
                        ),
                        for (int m = 1; m <= 12; m++)
                          DropdownMenuItem<int?>(
                            value: m,
                            child: Text(_monthName(m)),
                          ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedMonth = val);
                        _dispatchLoad();
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _buildBody(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TrustReportsState state) {
    if (state is TrustReportsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TrustReportsError) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(children: [
          SizedBox(
            height: 300,
            child: Center(child: Text('Error: ${state.message}')),
          ),
        ],),
      );
    }

    if (state is FinancialSummaryLoaded) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _SummaryGrid(summary: state.summary),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  static String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m - 1];
  }
}

class _SummaryGrid extends StatelessWidget {

  const _SummaryGrid({required this.summary});
  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        label: 'Total Revenue',
        value: _formatCurrency(summary.totalRevenue),
        color: Colors.green,
        icon: Icons.trending_up,
      ),
      _StatCardData(
        label: 'Total Expenses',
        value: _formatCurrency(summary.totalExpenses),
        color: Colors.red,
        icon: Icons.trending_down,
      ),
      _StatCardData(
        label: 'Net Balance',
        value: _formatCurrency(summary.netBalance),
        color: Colors.blue,
        icon: Icons.account_balance_outlined,
      ),
      _StatCardData(
        label: 'Total Invoices',
        value: '${summary.totalInvoices}',
        color: Colors.indigo,
        icon: Icons.receipt_long_outlined,
      ),
      _StatCardData(
        label: 'Paid Invoices',
        value: '${summary.paidInvoices}',
        color: Colors.teal,
        icon: Icons.check_circle_outline,
      ),
      _StatCardData(
        label: 'Pending Invoices',
        value: '${summary.pendingInvoices}',
        color: Colors.orange,
        icon: Icons.hourglass_empty_outlined,
      ),
      _StatCardData(
        label: 'Trust Balance',
        value: _formatCurrency(summary.trustBalance),
        color: Colors.purple,
        icon: Icons.security_outlined,
        fullWidth: true,
      ),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: cards.where((c) => !c.fullWidth).length,
          itemBuilder: (context, index) {
            final data = cards.where((c) => !c.fullWidth).toList()[index];
            return _StatCard(data: data);
          },
        ),
        const SizedBox(height: 12),
        // Full-width Trust Balance card
        ...cards.where((c) => c.fullWidth).map((data) => _StatCard(data: data, fullWidth: true)),
      ],
    );
  }

  static String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _StatCardData {

  const _StatCardData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool fullWidth;
}

class _StatCard extends StatelessWidget {

  const _StatCard({required this.data, this.fullWidth = false});
  final _StatCardData data;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(data.icon, color: data.color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.value,
              style: TextStyle(
                fontSize: fullWidth ? 26 : 20,
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 – Outstanding Balances
// ---------------------------------------------------------------------------

class _OutstandingBalancesTab extends StatefulWidget {
  const _OutstandingBalancesTab();

  @override
  State<_OutstandingBalancesTab> createState() =>
      _OutstandingBalancesTabState();
}

class _OutstandingBalancesTabState extends State<_OutstandingBalancesTab> {
  Future<void> _onRefresh() async {
    context.read<TrustReportsBloc>().add(LoadOutstandingBalances());
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrustReportsBloc, TrustReportsState>(
      listener: (context, state) {
        if (state is TrustReportsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        if (state is TrustReportsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TrustReportsError) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(children: [
              SizedBox(
                height: 300,
                child: Center(child: Text('Error: ${state.message}')),
              ),
            ],),
          );
        }

        if (state is OutstandingBalancesLoaded) {
          if (state.balances.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(children: [
                SizedBox(
                  height: 300,
                  child: Center(child: Text(AppLocalizations.of(context)!.noOutstandingBalances)),
                ),
              ],),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: state.balances.length,
              itemBuilder: (context, index) {
                final balance = state.balances[index];
                return _BalanceListTile(balance: balance, rank: index + 1);
              },
            ),
          );
        }

        // Initial state — waiting for tab selection trigger
        return Center(child: Text(AppLocalizations.of(context)!.selectTabToLoadData));
      },
    );
  }
}

class _BalanceListTile extends StatelessWidget {

  const _BalanceListTile({required this.balance, required this.rank});
  final OutstandingBalance balance;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final amountStr = '\$${balance.amount.toStringAsFixed(2)}';
    final invoiceLabel = balance.invoiceCount == 1
        ? '1 invoice'
        : '${balance.invoiceCount} invoices';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Text(
            '$rank',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          balance.customerName.isNotEmpty
              ? balance.customerName
              : 'Customer #${balance.customerId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(invoiceLabel),
        trailing: Text(
          amountStr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
