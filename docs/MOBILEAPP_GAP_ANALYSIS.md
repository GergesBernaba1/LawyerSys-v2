# MobileApp Gap Analysis Specification

## Overview

This document defines the feature gaps between **ClientApp** (web) and **MobileApp** (Flutter), providing a prioritized implementation roadmap for mobile parity.

---

## Current Status

### MobileApp Implemented Features

| Feature | Status |
|---------|--------|
| Authentication (login, register, forgot password, reset password) | ✅ Complete |
| Dashboard | ✅ Complete |
| Cases (list, detail) | ✅ Complete |
| Tasks (list, form) | ✅ Complete |
| Calendar | ✅ Complete |
| Billing (list, form) | ✅ Complete |
| Time Tracking (list, form) | ✅ Complete |
| Settings | ✅ Complete |
| Language Selection | ✅ Mobile-only |

---

## Missing Features by Priority

### Phase 1: Critical (Core Business)

| Feature | Category | Description |
|---------|----------|-------------|
| `customers` | People Management | Customer CRUD, profiles, search, case history |
| `employees` | People Management | Employee CRUD, roles, permissions, schedules |
| `sitings` | Legal Operations | Court hearings scheduling, calendar integration |
| `files` | Document Management | File upload, download, viewer, folder structure |

### Phase 2: Important (Operations)

| Feature | Category | Description |
|---------|----------|-------------|
| `courts` | Legal Operations | Court registry, jurisdictions, judges |
| `contenders` | Legal Operations | Opposing parties, conflict checks |
| `consultations` | Legal Operations | Consultation booking, notes, scheduling |
| `trust-accounting` | Financial | Trust ledger, receipts, disbursements |
| `client-portal` | Communication | Client messages, shared documents |

### Phase 3: Enhancement (Extended)

| Feature | Category | Description |
|---------|----------|-------------|
| `judicial` | Documents | Judicial orders, rulings, court filings |
| `governments` | Legal Operations | Government bodies, regions, jurisdictions |
| `caserelations` | Legal Operations | Case linking, parent-child relationships |
| `reports` | Analytics | Basic reports, summaries |
| `intake` | Client Acquisition | Intake forms, public submission |

### Phase 4: Optional (Future)

| Feature | Category | Description |
|---------|----------|-------------|
| `document-generation` | Documents | Template-based document creation |
| `esign` | Documents | Electronic signature workflows |
| `ai-assistant` | AI | AI-powered assistance |
| `administration` | Admin | System configuration (rare mobile need) |
| `tenants` | Platform | Multi-tenant management |
| `subscription` | Billing | Subscription management |
| `auditlogs` | Compliance | Audit trail viewing |
| `employee-workqueue` | Tasks | Duplicate of existing tasks feature |
| `contact-us` | Public | Web-only public page |
| `about-us` | Public | Web-only public page |

---

## Feature Specifications

### Phase 1: Customers

**Route**: `/customers`

**Screens**:
- `customers_list_screen.dart` - Grid/list view with search, filter, sort
- `customer_detail_screen.dart` - Customer profile, contact info, cases
- `customer_form_screen.dart` - Add/edit customer form

**Features**:
- Customer CRUD operations
- Contact information management
- Case history linkage
- Search by name, email, phone
- Filter by status (active/inactive)
- Pagination support

**API Endpoints**:
- `GET /api/customers`
- `GET /api/customers/{id}`
- `POST /api/customers`
- `PUT /api/customers/{id}`
- `DELETE /api/customers/{id}`

---

### Phase 1: Employees

**Route**: `/employees`

**Screens**:
- `employees_list_screen.dart` - Employee directory
- `employee_detail_screen.dart` - Employee profile, assignments
- `employee_form_screen.dart` - Add/edit employee

**Features**:
- Employee CRUD operations
- Role assignment
- Department allocation
- Contact details
- Active/inactive status

**API Endpoints**:
- `GET /api/employees`
- `GET /api/employees/{id}`
- `POST /api/employees`
- `PUT /api/employees/{id}`
- `DELETE /api/employees/{id}`

---

### Phase 1: Sitings (Hearings)

**Route**: `/sitings`

**Screens**:
- `sitings_list_screen.dart` - Upcoming hearings list
- `siting_detail_screen.dart` - Hearing details, outcomes
- `siting_form_screen.dart` - Schedule new hearing

**Features**:
- Hearing schedule management
- Courtroom assignment
- Attendee notifications
- Outcome recording
- Calendar integration (reuse existing calendar feature)
- Case linking

**API Endpoints**:
- `GET /api/sitings`
- `GET /api/sitings/{id}`
- `POST /api/sitings`
- `PUT /api/sitings/{id}`
- `DELETE /api/sitings/{id}`

---

### Phase 1: Files

**Route**: `/files`

**Screens**:
- `files_list_screen.dart` - File browser, folder view
- `file_viewer_screen.dart` - Document preview
- `file_upload_screen.dart` - Upload new files

**Features**:
- Folder navigation
- File upload (camera, gallery, documents)
- File preview (PDF, images)
- File download
- Case attachment
- Search files

**API Endpoints**:
- `GET /api/files`
- `GET /api/files/{id}`
- `POST /api/files/upload`
- `DELETE /api/files/{id}`
- `GET /api/files/{id}/download`

---

### Phase 2: Courts

**Route**: `/courts`

**Screens**:
- `courts_list_screen.dart` - Court registry
- `court_detail_screen.dart` - Court details, judges

**Features**:
- Court CRUD
- Jurisdiction mapping
- Judge assignment
- Court schedules

---

### Phase 2: Contenders

**Route**: `/contenders`

**Screens**:
- `contenders_list_screen.dart` - Opposing parties list
- `contender_detail_screen.dart` - Party details

**Features**:
- Opposing party CRUD
- Conflict-of-interest checks
- Case associations

---

### Phase 2: Consultations

**Route**: `/consultations`

**Screens**:
- `consultations_list_screen.dart` - Scheduled consultations
- `consultation_detail_screen.dart` - Consultation notes
- `consultation_form_screen.dart` - Book consultation

**Features**:
- Appointment scheduling
- Consultant assignment
- Notes recording
- Follow-up scheduling

---

### Phase 2: Trust Accounting

**Route**: `/trust-accounting`

**Screens**:
- `trust_list_screen.dart` - Trust transactions
- `trust_form_screen.dart` - Add receipt/disbursement

**Features**:
- Trust ledger entries
- Receipt recording
- Disbursement tracking
- Balance overview

---

### Phase 2: Client Portal

**Route**: `/client-portal`

**Screens**:
- `portal_messages_screen.dart` - Client messaging
- `portal_documents_screen.dart` - Shared documents

**Features**:
- Message threads with clients
- Document sharing
- Case updates viewing

---

## Technical Implementation Notes

### Shared Components to Create

```
lib/
├── shared/
│   ├── widgets/
│   │   ├── search_bar.dart
│   │   ├── filter_chip.dart
│   │   ├── empty_state.dart
│   │   └── pull_to_refresh.dart
│   └── utils/
│       └── date_formatter.dart (exists)
```

### Feature Folder Structure

```
lib/features/{feature_name}/
├── models/
│   └── {feature_name}.dart
├── repositories/
│   └── {feature_name}_repository.dart
├── bloc/
│   ├── {feature_name}_bloc.dart
│   ├── {feature_name}_event.dart
│   └── {feature_name}_state.dart
├── screens/
│   ├── {feature_name}_list_screen.dart
│   ├── {feature_name}_detail_screen.dart
│   └── {feature_name}_form_screen.dart
└── widgets/
    └── {feature_name}_card.dart
```

### Navigation

Add routes to `app.dart` following existing pattern:
```dart
Routes(
  customers: (context) => CustomersListScreen(),
  customerDetail: (context) => CustomerDetailScreen(),
  customerForm: (context) => CustomerFormScreen(),
  // ... etc
)
```

---

## Dependencies

Expected additional packages for implementation:
- `file_picker` - File selection
- `flutter_downloader` - File downloads
- `pdf_viewer` - PDF rendering
- `image_picker` - Camera/gallery access
- `path_provider` - Local storage paths

---

## Testing Requirements

- Unit tests for repositories
- Widget tests for screens
- Integration tests for critical flows
- Mock API responses for offline testing

---

## Timeline Estimate

| Phase | Features | Estimate |
|-------|----------|----------|
| Phase 1 | customers, employees, sitings, files | 2-3 sprints |
| Phase 2 | courts, contenders, consultations, trust, portal | 2 sprints |
| Phase 3 | judicial, governments, caserelations, reports, intake | 2 sprints |
| Phase 4 | document-generation, esign, ai-assistant | Future |
