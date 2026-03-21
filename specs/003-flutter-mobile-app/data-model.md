# Data Model Documentation: Flutter Mobile App

**Feature**: 003-flutter-mobile-app  
**Date**: 2026-03-20  
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the data models for the LawyerSys Flutter mobile application. Models are designed to mirror the ASP.NET Core API response structures for seamless integration, while also supporting offline storage in SQLite with tenant isolation.

## Design Principles

1. **API Parity**: Mobile models match backend DTOs to simplify JSON serialization/deserialization
2. **Tenant Isolation**: All cached entities include tenantId to enforce constitution requirement I
3. **Nullability**: Dart sound null safety used; nullable fields marked with `?` based on API contract
4. **Immutability**: Models are immutable (final fields) for predictable state management with BLoC
5. **Offline Support**: Models include sync metadata (lastSyncedAt, isDirty) for conflict detection

---

## Core Models

### UserSession

Represents authenticated user session with JWT tokens and tenant context.

**Purpose**: Manages authentication state and provides context for all API requests.

**Fields**:
```dart
class UserSession {
  final String userId;
  final String email;
  final String fullName;
  final String tenantId;
  final String tenantName;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiresAt;
  final List<String> roles;
  final List<String> permissions;
  final String languageCode;  // 'en' or 'ar'
  final bool biometricEnabled;
  
  UserSession({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.tenantId,
    required this.tenantName,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiresAt,
    required this.roles,
    required this.permissions,
    required this.languageCode,
    this.biometricEnabled = false,
  });
  
  // JSON serialization
  factory UserSession.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  // Token validation
  bool get isTokenExpired => DateTime.now().isAfter(tokenExpiresAt);
  
  // Permission checks
  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasRole(String role) => roles.contains(role);
}
```

**Storage**:
- Access/refresh tokens: flutter_secure_storage (encrypted)
- User metadata: shared_preferences (JSON string)
- Tenant context sent in X-Tenant-Id header for all API calls

**Validation Rules**:
- accessToken and refreshToken must be non-empty
- tokenExpiresAt must be future timestamp on creation
- languageCode must be 'en' or 'ar'

---

### DashboardSummary

Aggregated statistics for dashboard screen.

**Purpose**: Provides at-a-glance workload overview (US-001).

**Fields**:
```dart
class DashboardSummary {
  final String tenantId;
  final int totalCasesCount;
  final int activeCasesCount;
  final int upcomingHearingsCount;
  final int pendingTasksCount;
  final List<RecentActivity> recentActivities;
  final DateTime fetchedAt;
  
  DashboardSummary({
    required this.tenantId,
    required this.totalCasesCount,
    required this.activeCasesCount,
    required this.upcomingHearingsCount,
    required this.pendingTasksCount,
    required this.recentActivities,
    required this.fetchedAt,
  });
  
  factory DashboardSummary.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

class RecentActivity {
  final String activityId;
  final String activityType;  // 'CaseCreated', 'HearingScheduled', 'TaskAssigned'
  final String title;
  final String description;
  final DateTime timestamp;
  final String? relatedEntityId;  // Case ID, Hearing ID, etc.
  
  RecentActivity({
    required this.activityId,
    required this.activityType,
    required this.title,
    required this.description,
    required this.timestamp,
    this.relatedEntityId,
  });
  
  factory RecentActivity.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `dashboard_summary`
- Cache duration: 5 minutes (stale data refreshed on pull-to-refresh)

---

### Case

Legal case entity (US-002).

**Purpose**: Core business object representing a legal case with customer, court, and employee assignments.

**Fields**:
```dart
class Case {
  final String caseId;
  final String tenantId;
  final String caseNumber;
  final String invitationType;  // e.g., "Civil", "Criminal", "Family"
  final String caseStatus;  // e.g., "Open", "Closed", "Archived"
  final String caseType;
  final DateTime filingDate;
  final DateTime? closingDate;
  
  // Relationships
  final String customerId;
  final String customerFullName;
  final String? courtId;
  final String? courtName;
  final List<EmployeeAssignment> assignedEmployees;
  
  // Offline sync metadata
  final DateTime lastSyncedAt;
  final bool isDirty;  // true if edited offline
  
  Case({
    required this.caseId,
    required this.tenantId,
    required this.caseNumber,
    required this.invitationType,
    required this.caseStatus,
    required this.caseType,
    required this.filingDate,
    this.closingDate,
    required this.customerId,
    required this.customerFullName,
    this.courtId,
    this.courtName,
    required this.assignedEmployees,
    required this.lastSyncedAt,
    this.isDirty = false,
  });
  
  factory Case.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  // Helper methods
  bool get isOpen => caseStatus == 'Open';
  bool get isClosed => caseStatus == 'Closed';
}

class EmployeeAssignment {
  final String employeeId;
  final String employeeName;
  final String role;  // 'Primary Attorney', 'Associate', 'Paralegal'
  
  EmployeeAssignment({
    required this.employeeId,
    required this.employeeName,
    required this.role,
  });
  
  factory EmployeeAssignment.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `cases`
- Indexes: `tenantId`, `caseNumber`, `customerId`, `caseStatus`, `isDirty`
- Pagination: 20 cases per page in list view

**Validation Rules**:
- caseNumber must be unique per tenant
- filingDate cannot be future date
- closingDate must be after filingDate if present
- tenantId must match authenticated user's tenant

**State Transitions**:
- Open → Closed (only by users with 'CloseCase' permission)
- Closed → Archived (after retention period, admin only)

---

### Customer

Client entity (US-004).

**Purpose**: Contact information and case history for law firm clients.

**Fields**:
```dart
class Customer {
  final String customerId;
  final String tenantId;
  final String fullName;
  final String? ssn;
  final DateTime? birthDate;
  final String? phoneNumber;
  final String? mobileNumber;
  final String? email;
  final String? address;
  final String customerType;  // 'Individual', 'Organization'
  
  // Aggregated data
  final int associatedCasesCount;
  
  // Offline sync
  final DateTime lastSyncedAt;
  final bool isDirty;
  
  Customer({
    required this.customerId,
    required this.tenantId,
    required this.fullName,
    this.ssn,
    this.birthDate,
    this.phoneNumber,
    this.mobileNumber,
    this.email,
    this.address,
    required this.customerType,
    this.associatedCasesCount = 0,
    required this.lastSyncedAt,
    this.isDirty = false,
  });
  
  factory Customer.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  // Helper methods
  String? get primaryContactNumber => mobileNumber ?? phoneNumber;
  bool get hasContactInfo => phoneNumber != null || mobileNumber != null || email != null;
}
```

**Storage**:
- SQLite table: `customers`
- Indexes: `tenantId`, `fullName`, `ssn`
- Search fields: `fullName`, `ssn`, `phoneNumber`

**Validation Rules**:
- fullName required, min 2 characters
- ssn format validation if provided (locale-specific)
- phoneNumber/mobileNumber format validation (Saudi/regional patterns)
- email format validation if provided

---

### Hearing (Siting)

Court hearing/sitting entity (US-003).

**Purpose**: Court appearance tracking with calendar integration.

**Fields**:
```dart
class Hearing {
  final String hearingId;
  final String tenantId;
  final DateTime hearingDate;
  final String? hearingTime;  // Nullable as time may be TBD
  final String caseId;
  final String caseNumber;
  final String? judgeName;
  final String? courtId;
  final String? courtName;
  final String? courtLocation;
  final String hearingNotificationDetails;
  final String? notes;
  
  // Offline sync
  final DateTime lastSyncedAt;
  final bool isDirty;
  
  Hearing({
    required this.hearingId,
    required this.tenantId,
    required this.hearingDate,
    this.hearingTime,
    required this.caseId,
    required this.caseNumber,
    this.judgeName,
    this.courtId,
    this.courtName,
    this.courtLocation,
    required this.hearingNotificationDetails,
    this.notes,
    required this.lastSyncedAt,
    this.isDirty = false,
  });
  
  factory Hearing.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  // Helper methods
  bool get isUpcoming => hearingDate.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return hearingDate.year == now.year &&
           hearingDate.month == now.month &&
           hearingDate.day == now.day;
  }
}
```

**Storage**:
- SQLite table: `hearings`
- Indexes: `tenantId`, `hearingDate`, `caseId`
- Calendar view: Query by date range

**Validation Rules**:
- hearingDate cannot be more than 1 year in the past (archived hearings not shown in mobile)
- caseId must reference valid case in same tenant

---

### Court

Court entity.

**Purpose**: Court location and jurisdiction information.

**Fields**:
```dart
class Court {
  final String courtId;
  final String courtName;
  final String? address;
  final String? telephone;
  final String? governorateId;
  final String? governorateName;
  final String? notes;
  
  Court({
    required this.courtId,
    required this.courtName,
    this.address,
    this.telephone,
    this.governorateId,
    this.governorateName,
    this.notes,
  });
  
  factory Court.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `courts`
- Cached on first load, refreshed weekly (static reference data)

---

### Employee

Office staff/lawyer entity.

**Purpose**: Employee information for case assignments and contact.

**Fields**:
```dart
class Employee {
  final String employeeId;
  final String tenantId;
  final String fullName;
  final String role;  // 'Attorney', 'Paralegal', 'Administrator'
  final String? email;
  final String? phoneNumber;
  
  Employee({
    required this.employeeId,
    required this.tenantId,
    required this.fullName,
    required this.role,
    this.email,
    this.phoneNumber,
  });
  
  factory Employee.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `employees`
- Cached on first load, refreshed daily

---

### Document

Case-related file entity (US-007).

**Purpose**: Metadata for documents/files, with on-demand download.

**Fields**:
```dart
class Document {
  final String documentId;
  final String tenantId;
  final String caseId;
  final String fileName;
  final String fileType;  // 'PDF', 'Image', 'Word', etc.
  final String mimeType;
  final int fileSizeBytes;
  final DateTime uploadDate;
  final String uploadedByUserId;
  final String uploadedByUserName;
  final String? downloadUrl;  // Signed URL from backend
  
  // Local file path if downloaded
  final String? localFilePath;
  final bool isDownloaded;
  
  Document({
    required this.documentId,
    required this.tenantId,
    required this.caseId,
    required this.fileName,
    required this.fileType,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.uploadDate,
    required this.uploadedByUserId,
    required this.uploadedByUserName,
    this.downloadUrl,
    this.localFilePath,
    this.isDownloaded = false,
  });
  
  factory Document.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  // Helper methods
  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif'].contains(fileType.toLowerCase());
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

**Storage**:
- SQLite table: `documents` (metadata only)
- Files: Downloaded to app documents directory, managed by flutter_cache_manager with LRU eviction
- Documents not cached offline (too large), fetched on-demand

**Validation Rules**:
- fileSizeBytes must be > 0
- downloadUrl expires after 1 hour (backend generates signed URLs), re-request if expired

---

### Notification

Push/in-app notification entity (US-005).

**Purpose**: User notifications for events and reminders.

**Fields**:
```dart
class Notification {
  final String notificationId;
  final String tenantId;
  final String userId;
  final String notificationType;  // 'CaseAssigned', 'HearingReminder', 'TaskDue', 'SystemMessage'
  final String title;
  final String message;
  final String? relatedEntityType;  // 'Case', 'Hearing', 'Task'
  final String? relatedEntityId;
  final DateTime createdAt;
  final bool isRead;
  
  Notification({
    required this.notificationId,
    required this.tenantId,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
    this.isRead = false,
  });
  
  factory Notification.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `notifications`
- Retention: 30 days, auto-delete older notifications
- Push notification payload includes relatedEntityType/Id for navigation

---

### Governorate

Geographic/administrative region entity.

**Purpose**: Reference data for location-based filtering.

**Fields**:
```dart
class Governorate {
  final String governorateId;
  final String governorateName;
  
  Governorate({
    required this.governorateId,
    required this.governorateName,
  });
  
  factory Governorate.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `governorates`
- Cached on first load (static reference data)

---

### Contender

Opposing party entity.

**Purpose**: Track opposing parties in legal cases.

**Fields**:
```dart
class Contender {
  final String contenderId;
  final String tenantId;
  final String caseId;
  final String fullName;
  final String? ssn;
  final DateTime? birthDate;
  final String contenderType;  // 'Plaintiff', 'Defendant', 'Third Party'
  
  Contender({
    required this.contenderId,
    required this.tenantId,
    required this.caseId,
    required this.fullName,
    this.ssn,
    this.birthDate,
    required this.contenderType,
  });
  
  factory Contender.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `contenders`
- Loaded when viewing case details (not in main lists)

---

## Offline Sync Metadata

### SyncQueueItem

Tracks offline changes for synchronization.

**Purpose**: Persist offline edits for later sync with conflict detection.

**Fields**:
```dart
class SyncQueueItem {
  final String queueItemId;  // UUID
  final String tenantId;
  final String entityType;  // 'Case', 'Customer', 'Hearing'
  final String entityId;
  final String operationType;  // 'INSERT', 'UPDATE', 'DELETE'
  final Map<String, dynamic> payload;  // JSON of entity
  final DateTime createdAt;
  final int retryCount;
  final String? errorMessage;
  
  SyncQueueItem({
    required this.queueItemId,
    required this.tenantId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.errorMessage,
  });
  
  factory SyncQueueItem.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Storage**:
- SQLite table: `sync_queue`
- Processing order: createdAt ASC (FIFO)
- Max retries: 3 (then mark as failed, require manual resolution)

---

## Relationship Diagram

```
UserSession (1) --- (1) Tenant Context
    |
    +--- (N) Cases
            |
            +--- (1) Customer
            +--- (1) Court (optional)
            +--- (N) EmployeeAssignments
            +--- (N) Hearings
            +--- (N) Documents
            +--- (N) Contenders

Hearings (N) --- (1) Case
Hearings (N) --- (1) Court (optional)

Notifications (N) --- (1) User
Notifications (N) --- (1) RelatedEntity (optional)

SyncQueueItem (N) --- (1) Entity (via entityType + entityId)
```

---

## SQLite Schema

**Note**: sqflite does not support foreign keys by default (requires manual enablement). Relationships enforced in application logic.

```sql
-- Tenant context table (not synced, local tracking only)
CREATE TABLE user_session (
  id INTEGER PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  session_json TEXT NOT NULL  -- Full UserSession serialized
);

-- Cases
CREATE TABLE cases (
  case_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  case_number TEXT NOT NULL,
  invitation_type TEXT NOT NULL,
  case_status TEXT NOT NULL,
  case_type TEXT NOT NULL,
  filing_date INTEGER NOT NULL,  -- Unix timestamp
  closing_date INTEGER,
  customer_id TEXT NOT NULL,
  customer_full_name TEXT NOT NULL,
  court_id TEXT,
  court_name TEXT,
  assigned_employees_json TEXT,  -- List<EmployeeAssignment> serialized
  last_synced_at INTEGER NOT NULL,
  is_dirty INTEGER NOT NULL DEFAULT 0,  -- 0 = false, 1 = true
  UNIQUE(tenant_id, case_number)
);
CREATE INDEX idx_cases_tenant ON cases(tenant_id);
CREATE INDEX idx_cases_status ON cases(case_status);
CREATE INDEX idx_cases_customer ON cases(customer_id);
CREATE INDEX idx_cases_dirty ON cases(is_dirty);

-- Customers
CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  full_name TEXT NOT NULL,
  ssn TEXT,
  birth_date INTEGER,
  phone_number TEXT,
  mobile_number TEXT,
  email TEXT,
  address TEXT,
  customer_type TEXT NOT NULL,
  associated_cases_count INTEGER DEFAULT 0,
  last_synced_at INTEGER NOT NULL,
  is_dirty INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_customers_tenant ON customers(tenant_id);
CREATE INDEX idx_customers_name ON customers(full_name);

-- Hearings
CREATE TABLE hearings (
  hearing_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  hearing_date INTEGER NOT NULL,
  hearing_time TEXT,
  case_id TEXT NOT NULL,
  case_number TEXT NOT NULL,
  judge_name TEXT,
  court_id TEXT,
  court_name TEXT,
  court_location TEXT,
  hearing_notification_details TEXT NOT NULL,
  notes TEXT,
  last_synced_at INTEGER NOT NULL,
  is_dirty INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_hearings_tenant ON hearings(tenant_id);
CREATE INDEX idx_hearings_date ON hearings(hearing_date);
CREATE INDEX idx_hearings_case ON hearings(case_id);

-- Courts (reference data)
CREATE TABLE courts (
  court_id TEXT PRIMARY KEY,
  court_name TEXT NOT NULL,
  address TEXT,
  telephone TEXT,
  governorate_id TEXT,
  governorate_name TEXT,
  notes TEXT
);

-- Employees (reference data)
CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL,
  email TEXT,
  phone_number TEXT
);
CREATE INDEX idx_employees_tenant ON employees(tenant_id);

-- Documents (metadata only)
CREATE TABLE documents (
  document_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  case_id TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  upload_date INTEGER NOT NULL,
  uploaded_by_user_id TEXT NOT NULL,
  uploaded_by_user_name TEXT NOT NULL,
  download_url TEXT,
  local_file_path TEXT,
  is_downloaded INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_documents_tenant ON documents(tenant_id);
CREATE INDEX idx_documents_case ON documents(case_id);

-- Notifications
CREATE TABLE notifications (
  notification_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  related_entity_type TEXT,
  related_entity_id TEXT,
  created_at INTEGER NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_notifications_tenant ON notifications(tenant_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- Governorates (reference data)
CREATE TABLE governorates (
  governorate_id TEXT PRIMARY KEY,
  governorate_name TEXT NOT NULL
);

-- Contenders
CREATE TABLE contenders (
  contender_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  case_id TEXT NOT NULL,
  full_name TEXT NOT NULL,
  ssn TEXT,
  birth_date INTEGER,
  contender_type TEXT NOT NULL
);
CREATE INDEX idx_contenders_tenant ON contenders(tenant_id);
CREATE INDEX idx_contenders_case ON contenders(case_id);

-- Sync queue
CREATE TABLE sync_queue (
  queue_item_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation_type TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  retry_count INTEGER DEFAULT 0,
  error_message TEXT
);
CREATE INDEX idx_sync_queue_created ON sync_queue(created_at ASC);
CREATE INDEX idx_sync_queue_tenant ON sync_queue(tenant_id);

-- Dashboard summary cache
CREATE TABLE dashboard_summary (
  id INTEGER PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  summary_json TEXT NOT NULL,  -- DashboardSummary serialized
  fetched_at INTEGER NOT NULL
);
```

---

**End of Data Model Documentation**
