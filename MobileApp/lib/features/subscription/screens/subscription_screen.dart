import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_bloc.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_event.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_state.dart';
import 'package:qadaya_lawyersys/features/subscription/models/subscription_package.dart';
import 'package:qadaya_lawyersys/features/subscription/models/tenant_subscription.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<SubscriptionBloc>().add(LoadSubscriptionPackages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<SubscriptionBloc>()
      ..add(RefreshSubscriptionPackages());
    await bloc.stream.firstWhere(
      (s) => s is! SubscriptionLoading,
      orElse: () => bloc.state,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.subscription),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.star_outline), text: l.currentPlan),
            Tab(icon: const Icon(Icons.list_alt), text: l.availablePlans),
            Tab(icon: const Icon(Icons.receipt_long), text: l.billingHistory),
          ],
        ),
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l.error}: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SubscriptionLoaded) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CurrentPlanTab(subscription: state.currentSubscription),
                  _PackagesTab(packages: state.packages),
                  _BillingHistoryTab(
                    transactions: state.currentSubscription?.transactions ?? [],
                  ),
                ],
              ),
            );
          }

          if (state is SubscriptionError) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(child: Text('${l.error}: ${state.message}')),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Current Plan
// ---------------------------------------------------------------------------

class _CurrentPlanTab extends StatelessWidget {
  const _CurrentPlanTab({required this.subscription});
  final TenantSubscription? subscription;

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (subscription == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l.noActiveSubscription,
                style: const TextStyle(color: Colors.grey),),
          ],
        ),
      );
    }

    final sub = subscription!;
    final statusColor = sub.status.toLowerCase() == 'active'
        ? Colors.green
        : sub.status.toLowerCase() == 'expired'
            ? Colors.red
            : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header card
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sub.packageName.isNotEmpty
                              ? sub.packageName
                              : sub.officeSize,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4,),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),),
                        ),
                        child: Text(
                          sub.status,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,),
                        ),
                      ),
                    ],
                  ),
                  if (sub.price != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${sub.currency ?? r'$'}${sub.price!.toStringAsFixed(2)} / ${sub.billingCycle}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                  const Divider(height: 28),
                  _InfoRow(label: l.billingCycle, value: sub.billingCycle),
                  _InfoRow(label: l.startsOn, value: _fmt(sub.startDateUtc)),
                  _InfoRow(label: l.expiresOn, value: _fmt(sub.endDateUtc)),
                  _InfoRow(
                      label: l.nextBillingDate,
                      value: _fmt(sub.nextBillingDateUtc),),
                ],
              ),
            ),
          ),

          // Features
          if (sub.features.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l.features,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,),
            ),
            const SizedBox(height: 8),
            ...sub.features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Available Plans
// ---------------------------------------------------------------------------

class _PackagesTab extends StatelessWidget {
  const _PackagesTab({required this.packages});
  final List<SubscriptionPackage> packages;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (packages.isEmpty) {
      return Center(child: Text(l.noPackagesAvailable));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        return _PackageCard(package: packages[index]);
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});
  final SubscriptionPackage package;

  double? _yearlyDiscountPercent() {
    final monthly = package.monthlyPrice;
    final yearly = package.yearlyPrice;
    if (monthly == null || yearly == null || monthly <= 0) return null;
    final annualFromMonthly = monthly * 12;
    if (yearly >= annualFromMonthly) return null;
    return ((annualFromMonthly - yearly) / annualFromMonthly) * 100;
  }

  String _formatStorage(int? mb) {
    if (mb == null) return 'N/A';
    if (mb >= 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(gb.truncateToDouble() == gb ? 0 : 1)} GB';
    }
    return '$mb MB';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final discount = _yearlyDiscountPercent();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: package.isPopular ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: package.isPopular
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.officeSize,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (package.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4,),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Popular',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (package.name != null) ...[
              const SizedBox(height: 4),
              Text(
                package.name!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),),
                      Text(
                        package.monthlyPrice != null
                            ? '\$${package.monthlyPrice!.toStringAsFixed(2)}'
                            : l.contactSales,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Yearly',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12,),),
                          if (discount != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2,),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${discount.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        package.yearlyPrice != null
                            ? '\$${package.yearlyPrice!.toStringAsFixed(2)}'
                            : l.contactSales,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (package.maxUsers != null)
                  _LimitChip(
                    icon: Icons.people_outline,
                    label: '${package.maxUsers} Users',
                  ),
                if (package.maxCases != null)
                  _LimitChip(
                    icon: Icons.folder_open,
                    label: '${package.maxCases} Cases',
                  ),
                if (package.maxStorage != null)
                  _LimitChip(
                    icon: Icons.storage_outlined,
                    label: _formatStorage(package.maxStorage),
                  ),
              ],
            ),
            if (package.features.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...package.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: colorScheme.primary,),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature,
                            style: const TextStyle(fontSize: 14),),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.pleaseContactSales),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l.contactSales),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitChip extends StatelessWidget {
  const _LimitChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Billing History
// ---------------------------------------------------------------------------

class _BillingHistoryTab extends StatelessWidget {
  const _BillingHistoryTab({required this.transactions});
  final List<BillingTransaction> transactions;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'overdue':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l.noData, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final statusColor = _statusColor(tx.status);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tx.packageName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3,),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),),
                      ),
                      child: Text(
                        tx.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${tx.currency.isNotEmpty ? tx.currency : r'$'}${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,),
                    ),
                    const Spacer(),
                    Text(
                      tx.billingCycle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${l.dateLabel}: ${_fmt(tx.dueDateUtc)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (tx.paidAtUtc != null)
                  Text(
                    'Paid: ${_fmt(tx.paidAtUtc)}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                if (tx.reference != null && tx.reference!.isNotEmpty)
                  Text(
                    '${l.referenceNumber}: ${tx.reference}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
