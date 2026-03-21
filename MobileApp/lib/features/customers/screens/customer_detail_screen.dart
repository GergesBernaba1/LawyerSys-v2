import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cases/repositories/cases_repository.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/customers_event.dart';
import '../bloc/customers_state.dart';
import '../../../core/localization/app_localizations.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Future<List<CustomerCaseHistoryItem>> _caseHistoryFuture;

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(LoadCustomerDetail(widget.customerId));
    _caseHistoryFuture = context.read<CasesRepository>().getCasesByCustomerId(widget.customerId);
  }

  Future<void> _launchTelecommunication(String phoneNumber, String scheme, String errorMessage) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    final uri = Uri.parse('$scheme:$trimmed');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _dial(String phoneNumber) async {
    final localizer = AppLocalizations.of(context);
    await _launchTelecommunication(phoneNumber, 'tel', '${localizer.error}: ${localizer.call}');
  }

  Future<void> _sms(String phoneNumber) async {
    final localizer = AppLocalizations.of(context);
    await _launchTelecommunication(phoneNumber, 'sms', '${localizer.error}: ${localizer.message}');
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.customerDetail)),
      body: BlocBuilder<CustomersBloc, CustomersState>(
        builder: (context, state) {
          if (state is CustomersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomersError) {
            return Center(child: Text('${localizer.error}: ${state.message}'));
          }
          if (state is CustomerDetailLoaded) {
            final customer = state.customer;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(customer.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('${localizer.email}: ${customer.email ?? 'N/A'}'),
                const SizedBox(height: 6),
                Text('${localizer.customer}: ${customer.ssn ?? 'N/A'}'),
                const SizedBox(height: 6),
                Text('${localizer.phoneNumber}: ${customer.phoneNumber ?? 'N/A'}'),
                const SizedBox(height: 6),
                Text('${localizer.customer}: ${customer.address ?? 'N/A'}'),
                const SizedBox(height: 16),
                if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: Text(localizer.call),
                        onPressed: () => _dial(customer.phoneNumber!),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: Text(localizer.message),
                        onPressed: () => _sms(customer.phoneNumber!),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Text(localizer.caseHistory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FutureBuilder<List<CustomerCaseHistoryItem>>(
                  future: _caseHistoryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('${localizer.error}: ${snapshot.error}');
                    }
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return Text(localizer.noCaseHistory);
                    }
                    return Column(
                      children: history.map((entry) {
                        return ListTile(
                          title: Text(entry.caseName.isNotEmpty ? entry.caseName : entry.caseCode),
                          subtitle: Text('${localizer.caseCode}: ${entry.caseCode}${entry.assignedEmployeeName.isNotEmpty ? ' • ${localizer.assignedTo}: ${entry.assignedEmployeeName}' : ''}'),
                          onTap: () {
                            // Optionally navigate to case detail if full case data is available.
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
