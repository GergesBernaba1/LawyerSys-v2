import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';
import '../models/report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late int _year;
  late int _month;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    context.read<ReportsBloc>().add(
          LoadFinancialReport(year: _year, month: _month),
        );
  }

  void _refresh() {
    context.read<ReportsBloc>().add(
          RefreshReports(year: _year, month: _month),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Financial'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Outstanding'),
          ],
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            year: _year,
            month: _month,
            onChanged: (year, month) {
              setState(() {
                _year = year;
                _month = month;
              });
              _load();
            },
          ),
          Expanded(
            child: BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                if (state is ReportsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ReportsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${state.message}',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  );
                }
                if (state is ReportsLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _FinancialTab(state: state),
                      _OutstandingTab(
                          balances: state.outstandingBalances,
                          year: state.year,
                          month: state.month),
                    ],
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

// ── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  const _FilterBar(
      {required this.year,
      required this.month,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = [now.year - 1, now.year, now.year + 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          // Year picker
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: year,
              decoration: const InputDecoration(
                  labelText: 'Year', isDense: true),
              items: years
                  .map((y) =>
                      DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (v) => onChanged(v ?? year, month),
            ),
          ),
          const SizedBox(width: 12),
          // Month picker
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: month,
              decoration: const InputDecoration(
                  labelText: 'Month', isDense: true),
              items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                      value: i + 1, child: Text('${i + 1}'))),
              onChanged: (v) => onChanged(year, v ?? month),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Financial tab ───────────────────────────────────────────────────────────

class _FinancialTab extends StatelessWidget {
  final ReportsLoaded state;

  const _FinancialTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final report = state.financialReport;
    if (report == null) {
      return const Center(child: Text('No financial data'));
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<ReportsBloc>().add(
            RefreshReports(year: state.year, month: state.month),
          ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Summary cards
          Row(children: [
            Expanded(
                child: _SummaryCard(
                    label: 'Payments',
                    value: report.summary.totalPayments,
                    count: report.summary.paymentsCount,
                    color: Colors.red.shade100)),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryCard(
                    label: 'Receipts',
                    value: report.summary.totalReceipts,
                    count: report.summary.receiptsCount,
                    color: Colors.green.shade100)),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryCard(
                    label: 'Net',
                    value: report.summary.netCashFlow,
                    color: report.summary.netCashFlow >= 0
                        ? Colors.blue.shade100
                        : Colors.orange.shade100)),
          ]),
          const SizedBox(height: 16),

          // 6-month trend table
          Text('Last 6 Months',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Month')),
                  DataColumn(label: Text('Payments'), numeric: true),
                  DataColumn(label: Text('Receipts'), numeric: true),
                  DataColumn(label: Text('Net'), numeric: true),
                ],
                rows: report.last6Months
                    .map((p) => DataRow(cells: [
                          DataCell(Text(p.label)),
                          DataCell(Text(_fmt(p.payments))),
                          DataCell(Text(_fmt(p.receipts))),
                          DataCell(Text(
                            _fmt(p.netCashFlow),
                            style: TextStyle(
                                color: p.netCashFlow >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600),
                          )),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}

// ── Outstanding balances tab ────────────────────────────────────────────────

class _OutstandingTab extends StatelessWidget {
  final List<OutstandingBalance> balances;
  final int year;
  final int month;

  const _OutstandingTab({
    required this.balances,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ReportsBloc>().add(
                RefreshReports(year: year, month: month),
              );
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('No outstanding balances')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReportsBloc>().add(
              RefreshReports(year: year, month: month),
            );
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: balances.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final b = balances[index];
          final isPositive = b.outstandingBalance > 0;
          return ListTile(
            dense: true,
            title: Text(b.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Case total: ${b.casesTotalAmount.toStringAsFixed(2)}  •  Paid: ${b.paidAmount.toStringAsFixed(2)}'),
            trailing: Text(
              b.outstandingBalance.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.red : Colors.green,
              ),
            ),
            onTap: () => context
                .read<ReportsBloc>()
                .add(LoadCustomerBillingHistory(b.customerId)),
          );
        },
      ),
    );
  }
}

// ── Summary card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final int? count;
  final Color color;

  const _SummaryCard(
      {required this.label,
      required this.value,
      this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(2),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          if (count != null)
            Text('$count entries',
                style:
                    const TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }
}
