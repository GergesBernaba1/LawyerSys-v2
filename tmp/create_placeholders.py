import os
root = r'D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\MobileApp'
files = {
 'lib/features/hearings/models/hearing.dart': 'class Hearing {\n  final String hearingId;\n  Hearing({required this.hearingId});\n  factory Hearing.fromJson(Map<String, dynamic> json) => Hearing(hearingId: json["hearingId"]);\n  Map<String, dynamic> toJson() => {"hearingId": hearingId};\n}\n',
 'lib/features/hearings/repositories/hearings_repository.dart': 'class HearingsRepository {\n  Future<List> getHearings() async => [];\n}\n',
 'lib/features/hearings/bloc/hearings_event.dart': 'abstract class HearingsEvent {}\nclass LoadHearings extends HearingsEvent {}\n',
 'lib/features/hearings/bloc/hearings_state.dart': 'abstract class HearingsState {}\nclass HearingsInitial extends HearingsState {}\n',
 'lib/features/hearings/bloc/hearings_bloc.dart': 'import "hearings_event.dart";\nimport "hearings_state.dart";\nclass HearingsBloc {\n  HearingsState state = HearingsInitial();\n}\n',
 'lib/features/hearings/screens/hearings_list_screen.dart': 'import "package:flutter/material.dart";\nclass HearingsListScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Hearings List"))); }\n',
 'lib/features/hearings/screens/hearings_calendar_screen.dart': 'import "package:flutter/material.dart";\nclass HearingsCalendarScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Hearings Calendar"))); }\n',
 'lib/features/customers/models/customer.dart': 'class Customer { final String customerId; Customer({required this.customerId}); }\n',
 'lib/features/customers/repositories/customers_repository.dart': 'class CustomersRepository { Future<List> getCustomers() async => []; }\n',
 'lib/features/customers/bloc/customers_event.dart': 'abstract class CustomersEvent {} class LoadCustomers extends CustomersEvent {}\n',
 'lib/features/customers/bloc/customers_state.dart': 'abstract class CustomersState {} class CustomersInitial extends CustomersState {}\n',
 'lib/features/customers/bloc/customers_bloc.dart': 'import "customers_event.dart"; import "customers_state.dart"; class CustomersBloc { CustomersState state = CustomersInitial(); }\n',
 'lib/features/customers/screens/customers_list_screen.dart': 'import "package:flutter/material.dart"; class CustomersListScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Customers List"))); }\n',
 'lib/features/customers/screens/customer_detail_screen.dart': 'import "package:flutter/material.dart"; class CustomerDetailScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Customer Detail"))); }\n',
 'lib/features/notifications/models/notification.dart': 'class AppNotification { final String id; AppNotification(this.id); }\n',
 'lib/core/notifications/push_notification_service.dart': 'class PushNotificationService { Future<void> init() async {} }\n',
 'lib/core/notifications/notification_handler.dart': 'class NotificationHandler { void handle(Map<String,dynamic> message) {} }\n',
 'lib/features/notifications/repositories/notifications_repository.dart': 'class NotificationsRepository { Future<List> getNotifications() async => []; }\n',
 'lib/features/notifications/bloc/notifications_event.dart': 'abstract class NotificationsEvent {} class LoadNotifications extends NotificationsEvent {}\n',
 'lib/features/notifications/bloc/notifications_state.dart': 'abstract class NotificationsState {} class NotificationsInitial extends NotificationsState {}\n',
 'lib/features/notifications/bloc/notifications_bloc.dart': 'import "notifications_event.dart"; import "notifications_state.dart"; class NotificationsBloc { NotificationsState state = NotificationsInitial(); }\n',
 'lib/features/notifications/screens/notifications_screen.dart': 'import "package:flutter/material.dart"; class NotificationsScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Notifications"))); }\n',
 'lib/features/documents/models/document.dart': 'class Document { final String id; Document(this.id); }\n',
 'lib/features/documents/repositories/documents_repository.dart': 'class DocumentsRepository { Future<List> getDocumentsByCase(String caseId) async => []; }\n',
 'lib/features/documents/bloc/documents_event.dart': 'abstract class DocumentsEvent {} class LoadDocuments extends DocumentsEvent {}\n',
 'lib/features/documents/bloc/documents_state.dart': 'abstract class DocumentsState {} class DocumentsInitial extends DocumentsState {}\n',
 'lib/features/documents/bloc/documents_bloc.dart': 'import "documents_event.dart"; import "documents_state.dart"; class DocumentsBloc { DocumentsState state = DocumentsInitial(); }\n',
 'lib/features/documents/screens/document_viewer_screen.dart': 'import "package:flutter/material.dart"; class DocumentViewerScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Document Viewer"))); }\n',
 'lib/core/sync/conflict_resolver.dart': 'import "package:flutter/material.dart"; class ConflictResolverWidget extends StatelessWidget { @override Widget build(BuildContext context) => Container(child: Text("Conflict Resolver")); }\n',
 }
for relpath, content in files.items():
    path = os.path.join(root, relpath)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('CREATED', relpath)
print('Done placeholder generation.')
