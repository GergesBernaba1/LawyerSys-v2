import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_bloc.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_event.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_state.dart';

class CaseNotificationSettingsScreen extends StatefulWidget {

  const CaseNotificationSettingsScreen({super.key, required this.caseCode});
  final int caseCode;

  @override
  State<CaseNotificationSettingsScreen> createState() =>
      _CaseNotificationSettingsScreenState();
}

class _CaseNotificationSettingsScreenState
    extends State<CaseNotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<CustomersBloc>()
        .add(LoadCaseNotificationPreference(widget.caseCode));
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: BlocListener<CustomersBloc, CustomersState>(
        listener: (context, state) {
          if (state is CaseNotificationPreferenceUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Notification settings updated'),),
            );
          } else if (state is CustomersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizer.error}: ${state.message}')),
            );
          }
        },
        child: BlocBuilder<CustomersBloc, CustomersState>(
          builder: (context, state) {
            if (state is CustomersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CustomersError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${localizer.error}: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<CustomersBloc>().add(
                          LoadCaseNotificationPreference(widget.caseCode),),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            bool notificationsEnabled = false;
            if (state is CaseNotificationPreferenceLoaded) {
              notificationsEnabled = state.preference.notificationsEnabled;
            } else if (state is CaseNotificationPreferenceUpdated) {
              notificationsEnabled = state.preference.notificationsEnabled;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case #${widget.caseCode}',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage notification preferences for this case',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      context.read<CustomersBloc>().add(
                            UpdateCaseNotificationPreference(
                              widget.caseCode,
                              value,
                            ),
                          );
                    },
                    title: const Text('Enable Notifications'),
                    subtitle: const Text(
                      'Receive updates about case activities, document requests, and status changes',
                    ),
                    secondary: Icon(
                      notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: notificationsEnabled
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About Notifications',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'When enabled, you\'ll receive push notifications for:',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        ...[
                          'New document requests',
                          'Case status changes',
                          'Payment confirmations',
                          'Staff messages and updates',
                        ].map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
