import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/cases/repositories/cases_repository.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_bloc.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_event.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_state.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer.dart';
import 'package:qadaya_lawyersys/features/customers/screens/case_notification_settings_screen.dart';
import 'package:qadaya_lawyersys/features/customers/screens/payment_proof_submission_screen.dart';
import 'package:qadaya_lawyersys/features/customers/screens/requested_documents_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends StatefulWidget {

  const CustomerDetailScreen({super.key, required this.customerId, required this.casesRepository});
  final String customerId;
  final CasesRepository casesRepository;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Future<List<CustomerCaseHistoryItem>>? _caseHistoryFuture;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      BlocProvider.of<CustomersBloc>(context).add(LoadCustomerDetail(widget.customerId));
    }
  }

  Future<List<CustomerCaseHistoryItem>> get _caseHistory {
    _caseHistoryFuture ??= widget.casesRepository.getCasesByCustomerId(widget.customerId);
    return _caseHistoryFuture!;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _dial(String phoneNumber) async {
    final localizer = AppLocalizations.of(context)!;
    await _launchTelecommunication(phoneNumber, 'tel', '${localizer.error}: ${localizer.call}');
  }

  Future<void> _sms(String phoneNumber) async {
    final localizer = AppLocalizations.of(context)!;
    await _launchTelecommunication(phoneNumber, 'sms', '${localizer.error}: ${localizer.message}');
  }

  int? _parseCaseCode(String rawCode) {
    return int.tryParse(rawCode);
  }

  void _navigateToNotificationSettings(int caseCode) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CaseNotificationSettingsScreen(caseCode: caseCode),
      ),
    );
  }

  void _navigateToPaymentProof(int caseCode) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PaymentProofSubmissionScreen(caseCode: caseCode),
      ),
    );
  }

  void _navigateToRequestedDocuments(int caseCode) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RequestedDocumentsScreen(caseCode: caseCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

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
                  future: _caseHistory,
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
                        final caseCodeValue = _parseCaseCode(entry.caseCode);
                        return ListTile(
                          title: Text(entry.caseName.isNotEmpty ? entry.caseName : entry.caseCode),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.caseCode),
                              if (entry.assignedEmployeeName.isNotEmpty)
                                Text('${localizer.assignedTo}: ${entry.assignedEmployeeName}'),
                            ],
                          ),
                          trailing: caseCodeValue != null
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'notifications':
                                        _navigateToNotificationSettings(caseCodeValue);
                                        break;
                                      case 'paymentProof':
                                        _navigateToPaymentProof(caseCodeValue);
                                        break;
                                      case 'requestedDocuments':
                                        _navigateToRequestedDocuments(caseCodeValue);
                                        break;
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'notifications',
                                      child: Text(localizer.notifications),
                                    ),
                                    const PopupMenuItem(
                                      value: 'paymentProof',
                                      child: Text('Submit Payment Proof'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'requestedDocuments',
                                      child: Text('Requested Documents'),
                                    ),
                                  ],
                                )
                              : null,
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
