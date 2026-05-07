import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/skeleton_loader.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/customers_event.dart';
import '../bloc/customers_state.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../../cases/repositories/cases_repository.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(LoadCustomers());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<CustomersBloc>().add(LoadMoreCustomers());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.customers)),
      floatingActionButton: Semantics(
        label: 'Add new customer',
        hint: 'Tap to create a new customer',
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
            if (context.mounted) context.read<CustomersBloc>().add(RefreshCustomers());
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Semantics(
              label: 'Search customers',
              hint: 'Enter customer name or phone to search',
              textField: true,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizer.search,
                  suffixIcon: Semantics(
                    label: 'Search button',
                    hint: 'Tap to search customers',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        context.read<CustomersBloc>().add(SearchCustomers(_searchController.text));
                      },
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  context.read<CustomersBloc>().add(SearchCustomers(value));
                },
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<CustomersBloc, CustomersState>(
              listener: (context, state) {
                if (state is CustomerOperationSuccess) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is CustomersLoading) {
                  return const ListSkeleton(itemCount: 8);
                }
                if (state is CustomersError) {
                  return Center(child: Text('${localizer.error}: ${state.message}'));
                }
                if (state is CustomersLoaded) {
                  final customers = state.customers;
                  if (customers.isEmpty) {
                    return Center(child: Text(localizer.noCustomersFound));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CustomersBloc>().add(RefreshCustomers());
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: customers.length + (state.hasMore || state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= customers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final customer = customers[index];
                        return ListTile(
                          title: Text(customer.fullName),
                          subtitle: Text(customer.email ?? customer.phoneNumber ?? ''),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'call') {
                                _dial(customer.phoneNumber ?? '');
                              } else if (value == 'message') {
                                _sms(customer.phoneNumber ?? '');
                              } else if (value == 'edit') {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)));
                                if (context.mounted) context.read<CustomersBloc>().add(RefreshCustomers());
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(localizer.deleteCustomer),
                                    content: Text(localizer.deleteCustomerConfirm),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localizer.cancel)),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(localizer.delete)),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  context.read<CustomersBloc>().add(DeleteCustomer(customer.customerId));
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'call', child: Text(localizer.call)),
                              PopupMenuItem(value: 'message', child: Text(localizer.message)),
                              PopupMenuItem(value: 'edit', child: Text(localizer.edit)),
                              PopupMenuItem(value: 'delete', child: Text(localizer.delete)),
                            ],
                          ),
                          onTap: () {
                            final casesRepository = RepositoryProvider.of<CasesRepository>(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerDetailScreen(
                                  customerId: customer.customerId,
                                  casesRepository: casesRepository,
                                ),
                              ),
                            );
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
