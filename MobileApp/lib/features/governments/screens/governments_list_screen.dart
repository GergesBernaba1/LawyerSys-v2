import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
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
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<GovernmentsBloc>().add(LoadGovernments());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<GovernmentsBloc>().add(LoadGovernmentsNextPage());
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<GovernmentsBloc>().add(SearchGovernments(value.trim()));
      }
    });
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<GovernmentsBloc>()
      ..add(RefreshGovernments());
    await bloc.stream.firstWhere(
      (s) => s is GovernmentsLoaded || s is GovernmentsError,
      orElse: () => bloc.state,
    );
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
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const GovernmentFormScreen(),
            ),
          );
          if (context.mounted) {
            context.read<GovernmentsBloc>().add(RefreshGovernments());
          }
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
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocConsumer<GovernmentsBloc, GovernmentsState>(
              listener: (context, state) {
                if (state is GovernmentOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is GovernmentsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  );
                }

                if (state is GovernmentsError) {
                  return RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _onRefresh,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: _kTextSecondary,),
                                const SizedBox(height: 16),
                                Text('${AppLocalizations.of(context)!.error}: ${state.message}',
                                    style: const TextStyle(color: Colors.red),),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final GovernmentsLoaded? loaded = switch (state) {
                  GovernmentsLoaded() => state,
                  GovernmentsLoadingMore() => state.current,
                  _ => null,
                };

                if (loaded == null) return const SizedBox.shrink();

                if (loaded.governments.isEmpty) {
                  return RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _onRefresh,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_city,
                                    size: 64,
                                    color: _kTextSecondary.withValues(
                                        alpha: 0.5,),),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!
                                      .noGovernmentsFound,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4,),
                    itemCount: loaded.governments.length +
                        (state is GovernmentsLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => Divider(
                      color: _kPrimary.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      if (index == loaded.governments.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: _kPrimary),
                          ),
                        );
                      }
                      final gov = loaded.governments[index];
                      return _GovernmentTile(
                        government: gov,
                        onDeleted: () => context
                            .read<GovernmentsBloc>()
                            .add(DeleteGovernment(gov.governorateId),),
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

class _GovernmentTile extends StatelessWidget {
  const _GovernmentTile({
    required this.government,
    required this.onDeleted,
  });
  final Government government;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_city, color: _kPrimary, size: 24),
        ),
        title: Text(
          government.governorateName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                GovernmentDetailScreen(government: government),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      GovernmentFormScreen(government: government),
                ),
              );
              if (context.mounted) {
                context.read<GovernmentsBloc>().add(RefreshGovernments());
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.deleteGovernment),
                  content: Text(l.deleteGovernmentConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.cancel),),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l.delete),),
                  ],
                ),
              );
              if ((confirmed ?? false) && context.mounted) {
                onDeleted();
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l.edit),),
            PopupMenuItem(value: 'delete', child: Text(l.delete),),
          ],
        ),
      ),
    );
  }
}
