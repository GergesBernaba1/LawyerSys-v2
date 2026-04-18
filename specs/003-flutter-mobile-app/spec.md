# Feature Specification: Flutter Mobile App

**Feature Branch**: `003-flutter-mobile-app`  
**Created**: March 20, 2026  
**Status**: Draft  
**Input**: User description: "Create a Flutter mobile app for LawyerSys that connects to the existing ASP.NET Core API with a layout nearest current for our system"

## User Roles & Architecture

- **Multi-tenant architecture**: The app serves multiple law firms (tenants), each with isolated data
- **Staff roles**: Lawyers, paralegals, administrators access cases, hearings, customers based on permissions
- **Tenant context**: Sent via X-Tenant-Id header with every API request
- **Permission-based UI**: Features hidden/disabled based on user role permissions from backend

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Login and Dashboard Access (Priority: P1)

Lawyers and office staff need to authenticate securely on their mobile devices and immediately see an overview of their workload including pending cases, upcoming hearings, and recent activities.

**Why this priority**: Authentication is the gateway to all functionality. Without mobile authentication and a dashboard, the app provides no value. This is the foundation for all other features.

**Independent Test**: Can be fully tested by authenticating with valid credentials and verifying the dashboard displays accurate statistics for cases, hearings, and tasks. Delivers immediate value by providing workload visibility on mobile.

**Acceptance Scenarios**:

1. **Given** the app is opened for the first time, **When** a user enters valid email and password, **Then** the user is authenticated and redirected to the dashboard showing case count, upcoming hearings, and recent activities
2. **Given** the user has authenticated before, **When** the app is reopened, **Then** the session is restored automatically without requiring re-login
3. **Given** the user enters invalid credentials, **When** they attempt to log in, **Then** an error message is displayed in the user's selected language (Arabic or English)
4. **Given** the user is on the dashboard, **When** they pull to refresh, **Then** the statistics and recent activities are updated with latest data from the server
5. **Given** the user's session expires, **When** they attempt any action, **Then** they are redirected to the login screen with a message explaining session expiration

---

### User Story 2 - Case Management and Search (Priority: P1)

Lawyers need to quickly find, view, and update case information while away from the office, including case details, associated customers, court information, and current status.

**Why this priority**: Case management is the core function of a legal office system. Mobile access to case data enables lawyers to stay informed and make updates during court visits or client meetings.

**Independent Test**: Can be fully tested by searching for cases, viewing case details, and updating case information. Delivers value by enabling field work without returning to office.

**Acceptance Scenarios**:

1. **Given** the user is authenticated, **When** they navigate to the cases list, **Then** they see all cases they have permission to view with case number, customer name, invitation type, and status
2. **Given** the user is viewing the cases list, **When** they type in the search field, **Then** the list filters in real-time showing only cases matching the search term
3. **Given** the user selects a case, **When** the case details screen opens, **Then** they see complete case information including customer, court, employees, status, and related documents
4. **Given** the user has edit permissions, **When** they update case information and save, **Then** the changes are reflected immediately and synchronized with the backend
5. **Given** the user has no network connection, **When** they view previously loaded cases, **Then** cached case data is displayed with an indicator showing offline status

---

### User Story 3 - Hearing Schedule and Calendar View (Priority: P2)

Lawyers and staff need to view upcoming court hearings on their mobile devices, including hearing dates, times, associated cases, judge names, and court locations.

**Why this priority**: Missing a court hearing has serious legal consequences. Mobile access to hearing schedules helps lawyers manage their court calendar while traveling.

**Independent Test**: Can be fully tested by viewing the hearing list and calendar, filtering by date range, and viewing hearing details. Delivers value by preventing missed court appearances.

**Acceptance Scenarios**:

1. **Given** the user navigates to the hearings section, **When** the hearings list loads, **Then** they see all upcoming hearings sorted by date with case information, judge name, and hearing notification details
2. **Given** the user is viewing hearings, **When** they switch to calendar view, **Then** hearings are displayed on a monthly calendar with visual indicators for hearing dates
3. **Given** the user selects a hearing date on the calendar, **When** they tap the date, **Then** all hearings scheduled for that day are displayed in a list
4. **Given** the user has multiple hearings on the same day, **When** they view the day's schedule, **Then** hearings are ordered chronologically by hearing time
5. **Given** the user taps on a hearing, **When** the hearing details screen opens, **Then** they see complete information including related case details, court location, and any notes

---

### User Story 4 - Customer and Contact Management (Priority: P2)

Lawyers need quick mobile access to customer contact information, case history, and the ability to make calls or send messages directly from customer profiles.

**Why this priority**: Immediate access to customer information enables lawyers to respond to calls and communicate effectively while mobile. Integration with phone dialer and messaging apps enhances productivity.

**Independent Test**: Can be fully tested by searching for customers, viewing customer details with case history, and initiating calls or messages. Delivers value through rapid access to customer information during client communications.

**Acceptance Scenarios**:

1. **Given** the user navigates to the customers section, **When** the customer list loads, **Then** they see all customers with full name, phone number, and SSN
2. **Given** the user is viewing customers, **When** they search by name or SSN, **Then** the list filters to show matching customers in real-time
3. **Given** the user selects a customer, **When** the customer details screen opens, **Then** they see all customer information including contact details, address, and a list of associated cases
4. **Given** the user is viewing customer details, **When** they tap the phone number, **Then** the device dialer opens with the number pre-filled ready to call
5. **Given** the user is viewing a customer, **When** they navigate to the customer's cases tab, **Then** they see all cases associated with that customer with current status

---

### User Story 5 - Notifications and Real-time Updates (Priority: P3)

Users need to receive push notifications for important events such as new case assignments, upcoming hearings, task reminders, and system messages, keeping them informed even when the app is not actively used.

**Why this priority**: Proactive notifications prevent missed deadlines and keep lawyers informed of urgent matters. This enhances the mobile experience but is not essential for core functionality.

**Independent Test**: Can be fully tested by triggering various events that generate notifications and verifying notifications are received and displayable. Delivers value by reducing manual checking and preventing missed information.

**Acceptance Scenarios**:

1. **Given** the user has granted notification permissions, **When** a new hearing is scheduled for their case, **Then** they receive a push notification with the hearing date and case reference
2. **Given** the user receives a notification, **When** they tap the notification, **Then** the app opens directly to the relevant screen (case details, hearing details, etc.)
3. **Given** the user is using the app, **When** new data becomes available, **Then** in-app notifications or badges indicate updates without interrupting their current task
4. **Given** the user has multiple notifications, **When** they view the notifications center, **Then** all notifications are grouped by type and sorted by recency
5. **Given** the user dismisses or reads a notification, **When** the notification is marked as read, **Then** it is synchronized across all their devices

---

### User Story 6 - Bilingual Interface Support (Priority: P1)

All users must be able to switch between Arabic and English languages, with the interface adapting to show right-to-left (RTL) layout for Arabic and left-to-right (LTR) layout for English, maintaining consistency with the web application.

**Why this priority**: The system serves Arabic-speaking legal professionals. Bilingual support with proper RTL handling is mandatory for usability, not optional. Without this, the app is unusable for Arabic users.

**Independent Test**: Can be fully tested by switching languages and verifying all UI elements, navigation, and data display correctly in both languages with appropriate text direction. Delivers value by making the app accessible to all users regardless of language preference.

**Acceptance Scenarios**:

1. **Given** the user opens the app for the first time, **When** the language selection screen appears, **Then** they can choose Arabic or English before proceeding to login
2. **Given** the user selects Arabic, **When** any screen is displayed, **Then** all text, navigation, and layout elements are shown in RTL direction with Arabic text
3. **Given** the user is viewing any screen, **When** they change the language setting, **Then** the interface immediately updates to the new language without requiring app restart
4. **Given** data contains both Arabic and English text, **When** displayed in either language mode, **Then** the data is shown correctly without text overlap or layout breaks
5. **Given** the user switches languages, **When** they navigate through the app, **Then** all static text, labels, buttons, and error messages appear in the selected language

---

### User Story 7 - Document and File Access (Priority: P3)

Users need to view and download case-related documents and files from their mobile devices, including PDFs and images uploaded through the web application.

**Why this priority**: Access to case documents enhances mobile productivity but is not critical for core case tracking functionality. Many documents are better viewed on larger screens.

**Independent Test**: Can be fully tested by navigating to a case's files, viewing file lists, and downloading or opening files. Delivers value by enabling document review during meetings or court visits.

**Acceptance Scenarios**:

1. **Given** the user is viewing a case, **When** they navigate to the files tab, **Then** they see all documents associated with the case with file names and upload dates
2. **Given** the user selects a document, **When** the document is a PDF, **Then** it opens in the device's PDF viewer
3. **Given** the user selects an image file, **When** the file loads, **Then** it is displayed in an image viewer with zoom and pan capabilities
4. **Given** the user wants to save a file, **When** they tap the download button, **Then** the file is saved to the device's downloads folder with a confirmation message
5. **Given** the file is large, **When** it is being downloaded, **Then** a progress indicator shows the download percentage

---

### Edge Cases and Acceptance Scenarios

**Edge Case 1: Network Loss During Data Viewing/Editing**

- **Given** the user is viewing a list of cases with network connectivity, **When** the network connection is lost, **Then** the app displays previously cached data with a clear "Offline Mode" indicator
- **Given** the user is editing a case while offline, **When** they attempt to save changes, **Then** a message appears stating "Changes will be synchronized when connection is restored" and the edit is queued
- **Given** the user attempts to authenticate while offline, **When** they submit login credentials, **Then** the app displays an error message "Network connection required for authentication" and queues the login request
- **Given** the user has queued operations while offline, **When** network connectivity is restored, **Then** the app automatically processes the sync queue and notifies the user of successful synchronization

**Edge Case 2: Expired Authentication Token During Active Session**

- **Given** the user has an active session that has been open for 8 days (beyond 7-day token validity), **When** they attempt to load the dashboard, **Then** the app detects token expiration and displays a re-authentication dialog without navigating away from the dashboard
- **Given** the user is prompted to re-authenticate due to expired token, **When** they enter valid credentials, **Then** the app refreshes the JWT token, preserves the current screen context, and automatically completes the original dashboard load operation
- **Given** the refresh token is also expired, **When** re-authentication is attempted, **Then** the user is navigated to the login screen with a message explaining "Session expired - please log in again"

**Edge Case 3: Mobile App Version Incompatible with Backend API**

- **Given** the app is launched, **When** the API version check detects incompatibility, **Then** a full-screen modal appears with title "App Update Required" and message "This version is no longer compatible with the server. Please update to continue."
- **Given** the update required modal is displayed, **When** the user taps the "Update Now" button, **Then** the app opens the appropriate app store (Google Play or Apple App Store) to the app's update page
- **Given** the user dismisses the update modal, **When** they attempt to use any app feature, **Then** the modal reappears preventing app usage until updated
- **Given** the user has unsaved local data before version incompatibility is detected, **When** they update and relaunch the app, **Then** the local data is preserved and synced if compatible with the new version

**Edge Case 4: Large Data Sets (Thousands of Cases)**

- **Given** the user's office has 5000+ cases, **When** they navigate to the cases list, **Then** only the first 20-50 cases are loaded initially with a "Load More" button at the bottom
- **Given** the cases list is paginated, **When** the user scrolls to the end or taps "Load More", **Then** the next batch of 20-50 cases loads without requiring full page refresh
- **Given** the user searches for cases with the term "Smith", **When** the search is submitted, **Then** the API performs server-side filtering and returns only matching cases (not the full 5000+ records)
- **Given** the user filters cases by status "Active", **When** the filter is applied, **Then** the API performs server-side filtering and returns only active cases

**Edge Case 5: Push Notification Permissions Denied**

- **Given** the user has denied push notification permissions, **When** a new hearing is scheduled for their case, **Then** no push notification is sent but the hearing appears in the upcoming hearings list
- **Given** the user has denied push notification permissions, **When** they open the app, **Then** an in-app notification badge shows pending updates (e.g., "2 new events")
- **Given** the user navigates to Settings, **When** they view the notification preferences, **Then** the status shows "Push notifications disabled" with instructions to enable in device settings
- **Given** the user has denied push notification permissions, **When** they tap the pending updates badge, **Then** the notifications screen opens showing all recent events

**Edge Case 6: Multi-Tenant Isolation in Offline Mode**

- **Given** the user is logged into Tenant A and has cached 100 cases, **When** they log out and log into Tenant B, **Then** all Tenant A cached data is cleared before Tenant B data is loaded
- **Given** the user is working in Tenant A offline mode, **When** they edit a case, **Then** the edit is queued with tenant context and will only sync to Tenant A when connection is restored
- **Given** the user switches tenants while offline, **When** they attempt to access cached data, **Then** only data for the current tenant is visible and previous tenant data is inaccessible
- **Given** the user has queued offline operations for Tenant A, **When** they log into Tenant B, **Then** the Tenant A operations remain queued but are not processed until they log back into Tenant A

**Edge Case 7: Simultaneous Case Editing by Multiple Users**

- **Given** User A and User B both have Case #123 open for editing, **When** User A saves changes first, **Then** User B's screen shows an alert "This case has been modified by another user"
- **Given** User B receives the conflict alert, **When** they tap "Review Changes", **Then** a side-by-side comparison screen displays User B's unsaved changes versus the current server version
- **Given** User B is viewing the comparison screen, **When** they tap on individual fields, **Then** they can select which version to keep (their changes or server version) on a field-by-field basis
- **Given** User B has resolved conflicts for all fields, **When** they tap "Save Resolved Changes", **Then** the case updates with their selected field values and is synced to the server

## Clarifications

### Session 2026-03-20

- Q: When a user edits case data while offline and later reconnects, but another user has modified the same case in the meantime, how should conflicts be resolved? → A: Merge with user review and selective override - Show side-by-side comparison and let user choose field-by-field which changes to keep

### Session 2026-03-21

- Q: What is the target user model for the mobile app - single-tenant, multi-tenant, or client-facing? → A: Multi-tenant - Multiple law firms with staff roles (lawyers, paralegals, administrators) accessing cases, hearings, and customers based on permissions
- Q: What is the target reliability/SLA for the mobile app? → A: 99.5% uptime (4.38 hours downtime/month) - Standard business SLA
- Q: Should the mobile app have full feature parity with the web ClientApp or a subset? → A: Subset - Core mobile-friendly features only; web-only features (client portal, document generation, e-sign, administration panels) remain desktop-first
- Q: What rate limiting strategy should the mobile API client implement? → A: Standard - 60 requests/minute with exponential backoff on 429 responses
- Q: What observability/monitoring approach should be implemented? → A: Standard - Firebase Crashlytics for crash reporting + custom event logging for key user flows (login, case access, hearing views)
- Q: JWT tokens expire after a certain period for security. What should be the session timeout duration for mobile users before they need to re-authenticate? → A: 7 days - Session valid for one week with automatic refresh token renewal
- Q: The app will cache data for offline use. What is the maximum storage limit for offline cached data to prevent filling up the user's device storage? → A: 100MB - Moderate limit with user-configurable option in settings (min 50MB, max 500MB)
- Q: Push notifications are mentioned in the spec but the implementation approach wasn't specified. How should push notifications be delivered to mobile devices? → A: Native platform services - Firebase Cloud Messaging (FCM) for Android and Apple Push Notification service (APNs) for iOS
- Q: Mobile devices commonly support biometric authentication (fingerprint, Face ID). Should the app support biometric authentication as an alternative to password entry after initial login? → A: Optional biometric quick-unlock - Users can enable biometric authentication after initial password login for faster re-entry; password required on first login or when session fully expires

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST authenticate users using JWT bearer tokens obtained from the existing ASP.NET Core API with username and password
- **FR-002**: System MUST support optional biometric authentication (fingerprint, Face ID) for quick re-entry after initial password login, requiring password authentication on first login or when session fully expires
- **FR-003**: System MUST honor tenant isolation by sending tenant context with every API request and preventing cross-tenant data access
- **FR-004**: System MUST support both Arabic (RTL) and English (LTR) languages with complete UI adaptation including navigation direction, text alignment, and layout mirroring
- **FR-005**: System MUST display a dashboard showing case count, upcoming hearing count, pending tasks count, and recent activity list
- **FR-006**: System MUST provide a searchable list of all cases the authenticated user has permission to access, with filtering and sorting capabilities
- **FR-007**: System MUST display complete case details including customer information, court assignment, employee assignments, case status, invitation type, and related documents
- **FR-008**: System MUST allow users with appropriate permissions to create, update, and delete case records
- **FR-009**: System MUST display a list and calendar view of court hearings (sitings) with date, time, judge name, case reference, and location
- **FR-010**: System MUST allow users with appropriate permissions to create, update, and delete hearing records
- **FR-011**: System MUST provide a searchable list of customers with contact information and associated case history
- **FR-012**: System MUST integrate with device dialer and messaging apps for direct communication from customer profiles
- **FR-013**: System MUST cache previously loaded data for offline viewing with clear indicators when operating in offline mode, with a default 100MB storage limit that users can configure between 50MB and 500MB in settings
- **FR-014**: System MUST synchronize changes made offline with the backend when network connection is restored, using side-by-side conflict resolution that allows users to review and choose field-by-field which changes to keep when conflicts are detected
- **FR-015**: System MUST receive and display push notifications for new case assignments, upcoming hearings, and task reminders using native platform services (Firebase Cloud Messaging for Android and Apple Push Notification service for iOS)
- **FR-016**: System MUST provide access to case-related documents and files with ability to view PDFs, images, and download files to device storage
- **FR-017**: System MUST maintain user session across app restarts using secure token storage with a 7-day session validity period and automatic refresh token renewal
- **FR-018**: System MUST log all API calls, authentication events, data mutations, and sync operations for debugging and audit purposes with the following requirements:
  - Audit logs MUST include timestamp, user ID, tenant ID, action type, entity affected, and success/failure status
  - Audit logs MUST be retained locally for 90 days minimum and synced to backend when online
  - Audit logs MUST support filtering by user, tenant, date range, and action type for compliance reporting
  - Audit logs MUST be securely stored and cleared when user logs out or switches tenants
- **FR-019**: System MUST implement pull-to-refresh functionality on all list views to manually request updated data
- **FR-020**: System MUST use pagination for large data sets to optimize performance and reduce bandwidth usage with page sizes of 20-50 items per batch
- **FR-021**: System MUST respect user role and permission settings defined in the backend, hiding or disabling features user does not have access to
- **FR-022**: System MUST detect and handle API version incompatibilities by prompting user to update the app with a clear error message
- **FR-023**: System MUST provide a settings screen for language selection, notification preferences, offline cache size configuration (50-500MB), and about/version information
- **FR-024**: System MUST clear all cached data and stored credentials when user logs out except for language preference
- **FR-025**: System MUST display loading states during network operations and meaningful error messages for failed operations in the selected language
- **FR-026**: System MUST format dates, times, and numbers according to the selected language locale conventions
- **FR-027**: System MUST support iOS 13+ and Android 8.0+ (API level 26) as minimum platform versions

### Key Entities

- **User Session**: Represents authenticated user with JWT token, refresh token, tenant context, role/permissions, and language preference
- **Dashboard Summary**: Aggregated statistics including total cases, active cases, upcoming hearings count, pending tasks count, and recent activity items
- **Case**: Legal case with case number, customer reference, court assignment, employee assignments, invitation type, case status, case type, dates (filing, closing), and related entities (hearings, documents, files)
- **Customer**: Client information including full name, SSN/ID, birth date, phone numbers, address, email, associated cases list, and customer type
- **Hearing**: Court appearance with hearing date, hearing time, associated case, judge name, hearing notification details, court location, and notes
- **Court**: Court entity with court name, address, telephone, governorate/jurisdiction, and notes
- **Employee**: Office staff or lawyer with full name, role, contact information, and case assignments
- **Document/File**: Case-related files with file name, file type, upload date, file size, uploader user, and file content (downloadable)
- **Notification**: Push or in-app notification with notification type, title, message, related entity reference, timestamp, and read status
- **Governorate**: Geographic/administrative region entity with governorate name and associated courts
- **Contender**: Opposing party in a case with full name, SSN, birth date, and contender type

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete login and view their dashboard in under 10 seconds on typical mobile network (4G) conditions
- **SC-002**: Case search returns filtered results within 2 seconds for data sets up to 1000 cases
- **SC-003**: 90% of users successfully complete their first case lookup on first attempt without errors or confusion
- **SC-004**: All UI text and navigation elements correctly render in both Arabic RTL and English LTR modes without layout breaks or text overflow
- **SC-005**: App maintains usability with previously cached data for at least 15 minutes in offline mode
- **SC-006**: Push notifications are received within 30 seconds of the triggering event occurring on the server
- **SC-007**: Users can switch between Arabic and English languages with interface updating in less than 1 second
- **SC-008**: PDF documents up to 10MB open in under 5 seconds on typical mobile devices
- **SC-009**: App memory usage remains under 150MB during normal operation with typical data loads
- **SC-010**: Battery consumption is less than 5% per hour during active use with normal network conditions
- **SC-011**: 95% of API calls succeed on first attempt under normal server load conditions (defined as 100 concurrent users, <1000 requests/second, <50ms database query time)
- **SC-012**: Users require no more than 3 taps to reach any primary feature (cases, hearings, customers) from the dashboard
- **SC-013**: 90% of users successfully recover from API errors without app restart when error messages are clear and actionable
- **SC-014**: All screens render correctly with Arabic text strings up to 2x English length without layout breaks or text truncation
- **SC-015**: Navigation and touch targets remain accessible and tappable in RTL mode (minimum 44x44 point touch targets)

### Error Recovery Success Criteria

- **SC-016**: When network connection is lost during an operation, users receive a clear offline indicator message in their selected language
- **SC-017**: When authentication token expires, users are prompted to re-authenticate without losing their current screen context
- **SC-018**: When offline edits conflict with server data after reconnection, users see a side-by-side comparison and can choose which changes to keep
- **SC-019**: When API version is incompatible, users see a clear error message with a direct link to the app store for updating

### Audit and Compliance Success Criteria

- **SC-020**: Audit logs capture 100% of authentication events (login, logout, session refresh, biometric unlock)
- **SC-021**: Audit logs capture 100% of data mutation events (create, update, delete operations) with user ID, tenant ID, timestamp, and entity reference
- **SC-022**: Audit logs are queryable by user, tenant, date range, and action type for compliance reporting
- **SC-023**: Audit logs are retained for minimum 90 days and automatically cleared when user logs out or switches tenants
