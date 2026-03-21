# API Contracts: Flutter Mobile App

**Feature**: 003-flutter-mobile-app  
**Date**: 2026-03-20  
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the HTTP API contracts between the Flutter mobile app and the existing LawyerSys ASP.NET Core backend. The mobile app uses the same REST API endpoints as the web client, with additional headers for tenant isolation and JWT authentication.

## Base Configuration

**Base URL**: `https://api.lawyersys.example.com` (configurable per environment)  
**Content-Type**: `application/json` (all requests and responses)  
**Authentication**: JWT Bearer token in `Authorization` header  
**Tenant Context**: Tenant ID in `X-Tenant-Id` custom header  
**API Version**: Declared in `X-API-Version: 1.0` header for compatibility checking

---

## Authentication Endpoints

### POST /api/account/login

Authenticate user and obtain JWT tokens.

**Request**:
```json
{
  "email": "lawyer@example.com",
  "password": "SecurePassword123!",
  "rememberMe": true
}
```

**Response** (200 OK):
```json
{
  "userId": "usr_abc123",
  "email": "lawyer@example.com",
  "fullName": "Ahmed Al-Rashid",
  "tenantId": "tenant_xyz789",
  "tenantName": "Al-Rashid Law Firm",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "rt_def456ghi789",
  "tokenExpiresAt": "2026-03-21T00:19:00Z",
  "roles": ["Lawyer", "User"],
  "permissions": ["ViewCases", "EditCases", "ViewHearings", "EditHearings"],
  "languagePreference": "ar"
}
```

**Error Responses**:
- 401 Unauthorized: Invalid credentials
- 403 Forbidden: Account locked or disabled
- 500 Internal Server Error: Server error

---

### POST /api/account/refresh-token

Refresh expired access token using refresh token.

**Request**:
```json
{
  "refreshToken": "rt_def456ghi789"
}
```

**Response** (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "rt_new123abc456",
  "tokenExpiresAt": "2026-03-21T01:19:00Z"
}
```

**Error Responses**:
- 401 Unauthorized: Invalid or expired refresh token

---

### POST /api/account/logout

Invalidate current session tokens.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Request**: (empty body)

**Response** (204 No Content): Success

---

### POST /api/account/register-device-token

Register FCM device token for push notifications.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Request**:
```json
{
  "deviceToken": "fcm_token_xyz123abc456",
  "platform": "Android"  // or "iOS"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Device token registered successfully"
}
```

---

## Dashboard Endpoints

### GET /api/dashboard/summary

Get dashboard statistics for authenticated user.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Response** (200 OK):
```json
{
  "tenantId": "tenant_xyz789",
  "totalCasesCount": 147,
  "activeCasesCount": 89,
  "upcomingHearingsCount": 12,
  "pendingTasksCount": 23,
  "recentActivities": [
    {
      "activityId": "act_001",
      "activityType": "CaseCreated",
      "title": "New case filed",
      "description": "Case #2026-0045 - Mohammed Al-Saud vs. ABC Corporation",
      "timestamp": "2026-03-20T10:30:00Z",
      "relatedEntityId": "case_abc123"
    },
    {
      "activityId": "act_002",
      "activityType": "HearingScheduled",
      "title": "Hearing scheduled",
      "description": "Case #2026-0012 - Hearing on 2026-03-25 at 10:00 AM",
      "timestamp": "2026-03-19T14:15:00Z",
      "relatedEntityId": "hearing_def456"
    }
  ]
}
```

---

## Case Endpoints

### GET /api/cases

Get paginated list of cases.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Query Parameters**:
- `page` (int, default: 1): Page number
- `pageSize` (int, default: 20): Items per page
- `search` (string, optional): Search term (case number, customer name)
- `status` (string, optional): Filter by case status ('Open', 'Closed', 'Archived')
- `sortBy` (string, default: 'filingDate'): Sort field
- `sortOrder` (string, default: 'desc'): 'asc' or 'desc'

**Response** (200 OK):
```json
{
  "items": [
    {
      "caseId": "case_abc123",
      "tenantId": "tenant_xyz789",
      "caseNumber": "2026-0045",
      "invitationType": "Civil",
      "caseStatus": "Open",
      "caseType": "Contract Dispute",
      "filingDate": "2026-03-15T00:00:00Z",
      "closingDate": null,
      "customerId": "cust_001",
      "customerFullName": "Mohammed Al-Saud",
      "courtId": "court_001",
      "courtName": "Riyadh General Court",
      "assignedEmployees": [
        {
          "employeeId": "emp_001",
          "employeeName": "Ahmed Al-Rashid",
          "role": "Primary Attorney"
        }
      ]
    }
  ],
  "totalCount": 147,
  "page": 1,
  "pageSize": 20,
  "totalPages": 8
}
```

---

### GET /api/cases/{caseId}

Get detailed case information.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Response** (200 OK):
```json
{
  "caseId": "case_abc123",
  "tenantId": "tenant_xyz789",
  "caseNumber": "2026-0045",
  "invitationType": "Civil",
  "caseStatus": "Open",
  "caseType": "Contract Dispute",
  "filingDate": "2026-03-15T00:00:00Z",
  "closingDate": null,
  "customerId": "cust_001",
  "customerFullName": "Mohammed Al-Saud",
  "courtId": "court_001",
  "courtName": "Riyadh General Court",
  "assignedEmployees": [
    {
      "employeeId": "emp_001",
      "employeeName": "Ahmed Al-Rashid",
      "role": "Primary Attorney"
    }
  ],
  "hearings": [
    {
      "hearingId": "hearing_def456",
      "hearingDate": "2026-03-25T00:00:00Z",
      "hearingTime": "10:00 AM",
      "judgeName": "Judge Ali Al-Mutairi"
    }
  ],
  "documents": [
    {
      "documentId": "doc_001",
      "fileName": "Complaint.pdf",
      "fileType": "PDF",
      "fileSizeBytes": 2457600,
      "uploadDate": "2026-03-15T09:30:00Z"
    }
  ]
}
```

**Error Responses**:
- 404 Not Found: Case does not exist or not accessible to user

---

### PUT /api/cases/{caseId}

Update case information.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
X-Last-Modified: {lastSyncedAt}  // For conflict detection
```

**Request**:
```json
{
  "caseStatus": "Closed",
  "closingDate": "2026-03-20T00:00:00Z",
  "notes": "Case settled out of court"
}
```

**Response** (200 OK):
```json
{
  "caseId": "case_abc123",
  "lastModifiedAt": "2026-03-20T15:45:00Z",
  "message": "Case updated successfully"
}
```

**Error Responses**:
- 403 Forbidden: User lacks EditCases permission
- 409 Conflict: Case was modified by another user since lastSyncedAt (conflict resolution required)

**Conflict Response** (409):
```json
{
  "error": "ConflictDetected",
  "message": "Case has been modified by another user",
  "conflictingFields": ["caseStatus", "closingDate"],
  "currentServerState": {
    "caseStatus": "Open",
    "closingDate": null,
    "lastModifiedAt": "2026-03-20T14:30:00Z",
    "lastModifiedBy": "Sara Al-Fahd"
  },
  "yourChanges": {
    "caseStatus": "Closed",
    "closingDate": "2026-03-20T00:00:00Z"
  }
}
```

---

## Customer Endpoints

### GET /api/customers

Get paginated list of customers.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Query Parameters**:
- `page` (int, default: 1)
- `pageSize` (int, default: 20)
- `search` (string, optional): Search by name or SSN

**Response** (200 OK):
```json
{
  "items": [
    {
      "customerId": "cust_001",
      "tenantId": "tenant_xyz789",
      "fullName": "Mohammed Al-Saud",
      "ssn": "1234567890",
      "phoneNumber": "+966501234567",
      "mobileNumber": "+966509876543",
      "email": "mohammed@example.com",
      "customerType": "Individual",
      "associatedCasesCount": 3
    }
  ],
  "totalCount": 89,
  "page": 1,
  "pageSize": 20,
  "totalPages": 5
}
```

---

### GET /api/customers/{customerId}

Get detailed customer information with case history.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Response** (200 OK):
```json
{
  "customerId": "cust_001",
  "tenantId": "tenant_xyz789",
  "fullName": "Mohammed Al-Saud",
  "ssn": "1234567890",
  "birthDate": "1985-05-15T00:00:00Z",
  "phoneNumber": "+966501234567",
  "mobileNumber": "+966509876543",
  "email": "mohammed@example.com",
  "address": "123 King Fahd Road, Riyadh",
  "customerType": "Individual",
  "cases": [
    {
      "caseId": "case_abc123",
      "caseNumber": "2026-0045",
      "invitationType": "Civil",
      "caseStatus": "Open",
      "filingDate": "2026-03-15T00:00:00Z"
    }
  ]
}
```

---

## Hearing Endpoints

### GET /api/sitings

Get paginated list of hearings (sitings).

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Query Parameters**:
- `page` (int, default: 1)
- `pageSize` (int, default: 50)
- `startDate` (ISO 8601 date, optional): Filter hearings from this date
- `endDate` (ISO 8601 date, optional): Filter hearings until this date
- `caseId` (string, optional): Filter by case

**Response** (200 OK):
```json
{
  "items": [
    {
      "hearingId": "hearing_def456",
      "tenantId": "tenant_xyz789",
      "hearingDate": "2026-03-25T00:00:00Z",
      "hearingTime": "10:00 AM",
      "caseId": "case_abc123",
      "caseNumber": "2026-0045",
      "judgeName": "Judge Ali Al-Mutairi",
      "courtId": "court_001",
      "courtName": "Riyadh General Court",
      "courtLocation": "Building A, Floor 3, Room 305",
      "hearingNotificationDetails": "Preliminary hearing for contract dispute"
    }
  ],
  "totalCount": 12,
  "page": 1,
  "pageSize": 50,
  "totalPages": 1
}
```

---

### GET /api/sitings/{hearingId}

Get detailed hearing information.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Response** (200 OK):
```json
{
  "hearingId": "hearing_def456",
  "tenantId": "tenant_xyz789",
  "hearingDate": "2026-03-25T00:00:00Z",
  "hearingTime": "10:00 AM",
  "caseId": "case_abc123",
  "caseNumber": "2026-0045",
  "judgeName": "Judge Ali Al-Mutairi",
  "courtId": "court_001",
  "courtName": "Riyadh General Court",
  "courtLocation": "Building A, Floor 3, Room 305",
  "hearingNotificationDetails": "Preliminary hearing for contract dispute",
  "notes": "Bring witness statement documents",
  "relatedCase": {
    "caseNumber": "2026-0045",
    "customerName": "Mohammed Al-Saud",
    "invitationType": "Civil"
  }
}
```

---

## Document Endpoints

### GET /api/cases/{caseId}/files

Get list of documents for a case.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Response** (200 OK):
```json
{
  "items": [
    {
      "documentId": "doc_001",
      "tenantId": "tenant_xyz789",
      "caseId": "case_abc123",
      "fileName": "Complaint.pdf",
      "fileType": "PDF",
      "mimeType": "application/pdf",
      "fileSizeBytes": 2457600,
      "uploadDate": "2026-03-15T09:30:00Z",
      "uploadedByUserId": "usr_abc123",
      "uploadedByUserName": "Ahmed Al-Rashid",
      "downloadUrl": "https://api.lawyersys.example.com/api/files/download/doc_001?token=signed_url_token"
    }
  ]
}
```

---

### GET /api/files/download/{documentId}

Download document file (signed URL).

**Query Parameters**:
- `token` (string): Signed URL token (expires in 1 hour)

**Response** (200 OK):
- Content-Type: {mimeType from document}
- Content-Disposition: attachment; filename="{fileName}"
- Body: Binary file content

**Error Responses**:
- 401 Unauthorized: Invalid or expired token
- 404 Not Found: Document does not exist

---

## Reference Data Endpoints

### GET /api/courts

Get list of all courts (cached reference data).

**Headers**:
```
Authorization: Bearer {accessToken}
```

**Response** (200 OK):
```json
{
  "items": [
    {
      "courtId": "court_001",
      "courtName": "Riyadh General Court",
      "address": "King Fahd Road, Riyadh",
      "telephone": "+966112345678",
      "governorateId": "gov_001",
      "governorateName": "Riyadh"
    }
  ]
}
```

---

### GET /api/governorates

Get list of all governorates.

**Headers**:
```
Authorization: Bearer {accessToken}
```

**Response** (200 OK):
```json
{
  "items": [
    {
      "governorateId": "gov_001",
      "governorateName": "Riyadh"
    },
    {
      "governorateId": "gov_002",
      "governorateName": "Jeddah"
    }
  ]
}
```

---

### GET /api/employees

Get list of employees in tenant.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Response** (200 OK):
```json
{
  "items": [
    {
      "employeeId": "emp_001",
      "tenantId": "tenant_xyz789",
      "fullName": "Ahmed Al-Rashid",
      "role": "Attorney",
      "email": "ahmed@alrashidlaw.com",
      "phoneNumber": "+966501111111"
    }
  ]
}
```

---

## Notification Endpoints

### GET /api/notifications

Get list of user notifications.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Query Parameters**:
- `page` (int, default: 1)
- `pageSize` (int, default: 20)
- `unreadOnly` (bool, default: false): Filter to unread notifications

**Response** (200 OK):
```json
{
  "items": [
    {
      "notificationId": "notif_001",
      "tenantId": "tenant_xyz789",
      "userId": "usr_abc123",
      "notificationType": "HearingReminder",
      "title": "Upcoming Hearing",
      "message": "You have a hearing scheduled for tomorrow at 10:00 AM",
      "relatedEntityType": "Hearing",
      "relatedEntityId": "hearing_def456",
      "createdAt": "2026-03-19T14:15:00Z",
      "isRead": false
    }
  ],
  "totalCount": 5,
  "page": 1,
  "pageSize": 20,
  "totalPages": 1
}
```

---

### POST /api/notifications/{notificationId}/mark-read

Mark notification as read.

**Headers**:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

## Error Response Format

All error responses follow standardized format:

```json
{
  "error": "ErrorCode",
  "message": "Human-readable error message",
  "details": {
    "field": "Additional context"
  },
  "timestamp": "2026-03-20T15:45:00Z",
  "path": "/api/cases/123"
}
```

**Common Error Codes**:
- `Unauthorized`: Authentication failure
- `Forbidden`: Permission denied
- `NotFound`: Resource does not exist
- `ValidationError`: Request validation failed
- `ConflictDetected`: Offline sync conflict
- `TenantIsolationViolation`: Cross-tenant access attempt
- `InternalServerError`: Unexpected server error

---

## Rate Limiting

- Authenticated requests: 1000 requests per hour per user
- Login endpoint: 5 attempts per 15 minutes per IP (prevent brute force)
- Rate limit headers included in responses:
  - `X-RateLimit-Limit`: Total requests allowed
  - `X-RateLimit-Remaining`: Requests remaining
  - `X-RateLimit-Reset`: Unix timestamp when limit resets

---

**End of API Contracts Documentation**
