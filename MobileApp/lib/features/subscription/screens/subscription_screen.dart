import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_bloc.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_event.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_state.dart';
import 'package:qadaya_lawyersys/features/subscription/models/subscription_package.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(LoadSubscriptionPackages());
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<SubscriptionBloc>();
    bloc.add(RefreshSubscriptionPackages());
    await bloc.stream.firstWhere(
      (s) => s is! SubscriptionLoading,
      orElse: () => bloc.state,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.billing),
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SubscriptionError) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(child: Text('Error: ${state.message}')),
                  ),
                ],
              ),
            );
          }

          if (state is SubscriptionLoaded) {
            if (state.packages.isEmpty) {
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const Center(
                        child: Text('No packages available'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.packages.length,
                itemBuilder: (context, index) {
                  return _PackageCard(package: state.packages[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {

  const _PackageCard({required this.package});
  final SubscriptionPackage package;

  String _formatStorage(int? mb) {
    if (mb == null) return 'N/A';
    if (mb >= 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(gb.truncateToDouble() == gb ? 0 : 1)} GB';
    }
    return '$mb MB';
  }

  double? _yearlyDiscountPercent() {
    final monthly = package.monthlyPrice;
    final yearly = package.yearlyPrice;
    if (monthly == null || yearly == null || monthly <= 0) return null;
    final annualFromMonthly = monthly * 12;
    if (yearly >= annualFromMonthly) return null;
    return ((annualFromMonthly - yearly) / annualFromMonthly) * 100;
  }

  @override
  Widget build(BuildContext context) {
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
            // Header row: title + Popular badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.officeSize,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (package.isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

            // Pricing
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        package.monthlyPrice != null
                            ? '\$${package.monthlyPrice!.toStringAsFixed(2)}'
                            : 'Contact us',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Yearly
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Yearly',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12,),
                          ),
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
                            : 'Contact us',
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

            // Limits row
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

            // Features list
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

            // CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please contact sales@qadaya.com'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Contact Sales'),
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
