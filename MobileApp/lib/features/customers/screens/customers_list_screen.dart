import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/customers_bloc.dart';
import '../bloc/customers_event.dart';
import '../bloc/customers_state.dart';
import 'customer_detail_screen.dart';
import '../../core/localization/app_localizations.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      appBar: AppBar(title: Text(localizer.customers)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizer.search,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    context.read<CustomersBloc>().add(SearchCustomers(_searchController.text));
                  },
                ),
              ),
              onSubmitted: (value) {
                context.read<CustomersBloc>().add(SearchCustomers(value));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomersBloc, CustomersState>(
              builder: (context, state) {
                if (state is CustomersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CustomersError) {
                  return Center(child: Text('${localizer.error}: ${state.message}'));
                }
                if (state is CustomersLoaded) {
                  final customers = state.customers;
                  if (customers.isEmpty) {
                    return Center(child: Text(localizer.noDataAvailable));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CustomersBloc>().add(RefreshCustomers());
                    },
                    child: ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return ListTile(
                          title: Text(customer.fullName),
                          subtitle: Text(customer.customerId),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'call') {
                                _dial(customer.phoneNumber ?? '');
                              } else if (value == 'message') {
                                _sms(customer.phoneNumber ?? '');
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'call', child: Text(localizer.call)),
                              PopupMenuItem(value: 'message', child: Text(localizer.message)),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.customerId)));
                          },
                        );
                      },
                    ),
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
