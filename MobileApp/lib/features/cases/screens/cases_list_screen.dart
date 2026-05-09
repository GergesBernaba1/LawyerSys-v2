import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_event.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_state.dart';
import 'package:qadaya_lawyersys/features/cases/models/case.dart';
import 'package:qadaya_lawyersys/features/cases/screens/case_detail_screen.dart';
import 'package:qadaya_lawyersys/shared/widgets/skeleton_loader.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kGold = Color(0xFFB98746);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<CasesBloc>().add(LoadCases());
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
      context.read<CasesBloc>().add(LoadMoreCases());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return BlocListener<CasesBloc, CasesState>(
      listener: (context, state) {
        if (state is CaseOperationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          context.read<CasesBloc>().add(RefreshCases());
        }
        if (state is CasesError) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizer.error}: ${state.message}')),);
        }
      },
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Semantics(
              label: 'Search cases',
              hint: 'Enter case number or client name to search',
              textField: true,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizer.searchCases,
                  hintStyle: const TextStyle(color: _kTextSecondary),
                  prefixIcon: const Icon(Icons.search, color: _kPrimary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? Semantics(
                          label: 'Clear search',
                          hint: 'Tap to clear search text',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: _kTextSecondary),
                            onPressed: () {
                              _searchController.clear();
                              context.read<CasesBloc>().add(LoadCases());
                            },
                          ),
                        )
                      : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kPrimary, width: 2),
                ),
              ),
              onSubmitted: (v) => context.read<CasesBloc>().add(SearchCases(v)),
              onChanged: (_) => setState(() {}),
            ),
          ),
          ),

          // Status filter chips
          Builder(
            builder: (ctx) {
              final l = AppLocalizations.of(ctx)!;
              final chips = [
                (null, l.all),
                (0, l.statusOpen),
                (1, l.statusInProgress),
                (2, l.statusAwaitingHearing),
                (3, l.statusClosed),
                (4, l.statusWon),
                (5, l.statusLost),
              ];
              return SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final (value, label) = chips[i];
                    final selected = _statusFilter == value;
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _statusFilter = value);
                      },
                      selectedColor: _kPrimary.withValues(alpha: 0.15),
                      checkmarkColor: _kPrimary,
                      labelStyle: TextStyle(
                        color: selected ? _kPrimary : _kTextSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 4,),

          // List
          Expanded(
            child: BlocBuilder<CasesBloc, CasesState>(
              builder: (context, state) {
                if (state is CasesLoading) {
                  return const ListSkeleton(itemCount: 8);
                }
                if (state is CasesError) {
                  return Center(
                      child: Text('${localizer.error}: ${state.message}',
                          style: const TextStyle(color: Colors.red),),);
                }
                if (state is CasesLoaded) {
                  final cases = _statusFilter == null
                      ? state.cases
                      : state.cases.where((c) => c.status == _statusFilter).toList();
                  if (cases.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open,
                              size: 64,
                              color: _kPrimary.withValues(alpha: 0.3),),
                          const SizedBox(height: 12),
                          Text(localizer.noCasesFound,
                              style: const TextStyle(
                                  color: _kTextSecondary,
                                  fontWeight: FontWeight.w600,),),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: () async =>
                        context.read<CasesBloc>().add(RefreshCases()),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: cases.length + (state.hasMore || state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= cases.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                              ),
                            ),
                          );
                        }
                        return _CaseTile(caseItem: cases[index]);
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

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.caseItem});
  final CaseModel caseItem;

  Color _statusColor(int status) {
    switch (status) {
      case 1: // InProgress
      case 2: // AwaitingHearing
        return const Color(0xFF10B981);
      case 3: // Closed
      case 5: // Lost
        return const Color(0xFF6B7280);
      case 4: // Won
        return _kGold;
      default: // New / unknown
        return _kPrimaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusColor = _statusColor(caseItem.status);

    String localizedStatus(int s) {
      switch (s) {
        case 0: return l.statusOpen;
        case 1: return l.statusInProgress;
        case 2: return l.statusAwaitingHearing;
        case 3: return l.statusClosed;
        case 4: return l.statusWon;
        case 5: return l.statusLost;
        default: return s.toString();
      }
    }

    final statusLabel = localizedStatus(caseItem.status);

    return Semantics(
      label: 'Case ${caseItem.caseNumber}, ${caseItem.invitionType}, status $statusLabel',
      hint: 'Double tap to view case details',
      button: true,
      onTapHint: 'Open case details',
      child: GestureDetector(
        onTap: () {
          context.read<CasesBloc>().add(SelectCase(caseItem.caseId));
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => CaseDetailScreen(caseModel: caseItem),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: _kText.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kPrimaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.gavel, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseItem.caseNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _kText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      caseItem.invitionType,
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
