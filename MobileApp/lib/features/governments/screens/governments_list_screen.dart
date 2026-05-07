import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/l10n/app_localizations.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_bloc.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_event.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_state.dart';
import 'package:qadaya_lawyersys/features/governments/models/government.dart';
import 'package:qadaya_lawyersys/features/governments/screens/government_detail_screen.dart';
import 'package:qadaya_lawyersys/features/governments/screens/government_form_screen.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class GovernmentsListScreen extends StatefulWidget {
  const GovernmentsListScreen({super.key});

  @override
  State<GovernmentsListScreen> createState() => _GovernmentsListScreenState();
}

class _GovernmentsListScreenState extends State<GovernmentsListScreen> {
  final _searchController = TextEditingController();
  List<Government> _filtered = [];

  @override
  void initState() {
    super.initState();
    context.read<GovernmentsBloc>().add(LoadGovernments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(List<Government> all) {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? all
          : all
              .where((g) => g.governorateName.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.governments),
        backgroundColor: _kPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const GovernmentFormScreen()));
          if (context.mounted) context.read<GovernmentsBloc>().add(RefreshGovernments());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search, color: _kPrimaryLight),
                filled: true,
                fillColor: _kPrimary.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) {
                final state = context.read<GovernmentsBloc>().state;
                if (state is GovernmentsLoaded) _applyFilter(state.governments);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocConsumer<GovernmentsBloc, GovernmentsState>(
              listener: (context, state) {
                if (state is GovernmentsLoaded) _applyFilter(state.governments);
              },
              builder: (context, state) {
                if (state is GovernmentsLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _kPrimary),);
                }
                if (state is GovernmentsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: _kTextSecondary,),
                        const SizedBox(height: 16),
                        Text('${l.error}: ${state.message}',
                            style: const TextStyle(color: Colors.red),),
                      ],
                    ),
                  );
                }
                if (state is GovernmentOperationSuccess) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message)),);
                    }
                  });
                }
                if (_filtered.isEmpty && state is GovernmentsLoaded) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_city,
                            size: 64,
                            color: _kTextSecondary.withValues(alpha: 0.5),),
                        const SizedBox(height: 16),
                        Text(
                          l.noGovernmentsFound,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: () async {
                    context.read<GovernmentsBloc>().add(RefreshGovernments());
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) => Divider(
                      color: _kPrimary.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final gov = _filtered[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _kText.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12,),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_city,
                                color: _kPrimary, size: 24,),
                          ),
                          title: Text(
                            gov.governorateName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${gov.governorateId}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kTextSecondary,
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GovernmentDetailScreen(government: gov),
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              final gov = _filtered[index];
                              if (value == 'edit') {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => GovernmentFormScreen(government: gov)));
                                if (context.mounted) context.read<GovernmentsBloc>().add(RefreshGovernments());
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l.deleteGovernment),
                                    content: Text(l.deleteGovernmentConfirm),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                                    ],
                                  ),
                                );
                                if ((confirmed ?? false) && context.mounted) {
                                  context.read<GovernmentsBloc>().add(DeleteGovernment(gov.governorateId));
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text(l.edit)),
                              PopupMenuItem(value: 'delete', child: Text(l.delete)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
