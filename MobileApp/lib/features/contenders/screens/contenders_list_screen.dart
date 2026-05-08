import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_bloc.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_event.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_state.dart';
import 'package:qadaya_lawyersys/features/contenders/models/contender.dart';
import 'package:qadaya_lawyersys/features/contenders/screens/contender_detail_screen.dart';
import 'package:qadaya_lawyersys/features/contenders/screens/contender_form_screen.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class ContendersListScreen extends StatefulWidget {
  const ContendersListScreen({super.key});

  @override
  State<ContendersListScreen> createState() => _ContendersListScreenState();
}

class _ContendersListScreenState extends State<ContendersListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<ContendersBloc>().add(LoadContenders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<ContendersBloc>().add(SearchContenders(value.trim()));
      }
    });
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<ContendersBloc>()..add(RefreshContenders());
    await bloc.stream.firstWhere(
      (s) => s is ContendersLoaded || s is ContendersError,
      orElse: () => bloc.state,
    );
  }

  Future<void> _confirmDelete(BuildContext context, ContenderModel c) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteContender),
        content: Text(l.deleteContenderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<ContendersBloc>().add(DeleteContender(c.contenderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.contenders),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ContenderFormScreen()),
          );
          if (context.mounted) {
            context.read<ContendersBloc>().add(RefreshContenders());
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
            child: BlocConsumer<ContendersBloc, ContendersState>(
              listener: (context, state) {
                if (state is ContendersError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l.error}: ${state.message}')),
                  );
                }
                if (state is ContenderOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is ContendersLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  );
                }

                if (state is ContendersError) {
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
                                Text(
                                  '${l.error}: ${state.message}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ContendersLoaded) {
                  final contenders = state.contenders;

                  if (contenders.isEmpty) {
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
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: _kTextSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l.noContendersFound,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4,),
                      itemCount: contenders.length,
                      separatorBuilder: (_, __) => Divider(
                        color: _kPrimary.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final c = contenders[index];
                        return _ContenderTile(
                          contender: c,
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ContenderFormScreen(contender: c),
                              ),
                            );
                            if (context.mounted) {
                              context.read<ContendersBloc>().add(RefreshContenders());
                            }
                          },
                          onDelete: () => _confirmDelete(context, c),
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

class _ContenderTile extends StatelessWidget {
  const _ContenderTile({
    required this.contender,
    required this.onEdit,
    required this.onDelete,
  });

  final ContenderModel contender;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPlaintiff = contender.type ?? false;
    final typeLabel = contender.type == null
        ? '—'
        : (isPlaintiff ? l.plaintiff : l.defendant);
    final typeColor = isPlaintiff ? const Color(0xFF1565C0) : const Color(0xFFC62828);

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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_outline, color: _kPrimary, size: 22),
        ),
        title: Text(
          contender.fullName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (contender.ssn.isNotEmpty)
              Text(
                '${l.ssn}: ${contender.ssn}',
                style:
                    const TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ContenderDetailScreen(contender: contender),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l.edit)),
            PopupMenuItem(
              value: 'delete',
              child: Text(l.delete,
                  style: const TextStyle(color: Colors.red),),
            ),
          ],
        ),
      ),
    );
  }
}
