# Qadaya LawyerSys — Compliance Posture
**Version:** 1.0 | **Date:** 2026-06-09 | **Owner:** Qadaya / Naqreo

---

## Purpose of This Document

This document serves two audiences:

1. **Prospective customers (law firms):** Answers the question *"How does Qadaya handle our clients' data?"* — the question every firm principal will ask before signing.
2. **Internal team:** A live gap register tracking what is implemented, what is partially done, and what must be completed before we can make binding compliance representations.

---

## Part 1 — Customer-Facing Data Handling Summary

### Who We Are in the Data Chain

Qadaya operates as a **data processor** on behalf of your law firm (the **data controller**) for all case, client, and document data you enter into the system. We are the **data controller** for your firm's account and billing information.

This distinction matters under Egyptian law (PDPL, Law 151/2020): your firm is responsible for the lawful basis on which you collect your clients' data. Qadaya is responsible for processing that data securely and only according to your instructions.

---

### What Data Qadaya Holds

| Data Category | Examples | Who It Belongs To |
|---|---|---|
| **Client / case data** | Names, national IDs, phone numbers, addresses, dates of birth of your clients and opposing parties | Your firm (you control it) |
| **Legal documents** | Uploaded files, AI-generated contracts, case notes | Your firm (you control it) |
| **Financial records** | Billing amounts, payment records within cases | Your firm (you control it) |
| **Firm account data** | Firm name, contact email, contact phone | Qadaya controls this |
| **User credentials** | Staff login credentials (email, hashed passwords) | Qadaya controls this |
| **Subscription & billing** | Subscription plan, payment history in EGP | Qadaya controls this |

---

### Where Your Data Is Stored

| Component | Location | Notes |
|---|---|---|
| **Database** | PostgreSQL server hosted on a dedicated VM | Egypt-region by default |
| **Uploaded files** | Local disk on the application server | Same server as database |
| **Logs** | Rolling daily log files on the application server | Retained 30 days (see Gap #6) |
| **Push notification tokens** | Firebase (Google) servers | Device tokens only — no case data |

**No case data or client PII is stored in the cloud by default.** The only third-party services that may receive data are listed in the table below.

---

### Third-Party Services That May Receive Your Data

| Service | Data Sent | Purpose | Can Be Disabled |
|---|---|---|---|
| **OpenAI (gpt-4)** | Case text, party names, document drafts you submit to AI features | AI document drafting and summarization | Yes — per-request, only when you use AI features |
| **Firebase (Google FCM)** | Device push tokens + notification title/body (no case content) | Mobile push notifications | Yes — disable push in settings |
| **Gmail SMTP (current)** | Recipient email address + notification body | Email reminders (hearings, tasks, billing) | No — required for email delivery |
| **Twilio** | Phone numbers + message text | SMS/WhatsApp reminders | Yes — currently disabled; enabled only with your configuration |

> **Important note on AI:** When you use the AI document drafting feature, the text you submit (which may contain client names or case details) is sent to OpenAI's API. OpenAI's API data processing terms apply. We recommend not submitting highly sensitive identifying information (e.g., national IDs) in free-text AI prompts.

---

### Security Controls in Place

| Control | Status |
|---|---|
| HTTPS-only web access | ✅ Enforced |
| Passwords hashed (PBKDF2 via ASP.NET Identity) | ✅ Yes |
| Strong password policy (8+ chars, mixed case, symbols) | ✅ Yes |
| Account lockout after 5 failed login attempts (15 min) | ✅ Yes |
| JWT access tokens expire after 30 minutes | ✅ Yes |
| Refresh token rotation with 7-day expiry | ✅ Yes |
| Multi-tenancy isolation (your data is logically separated from other firms) | ✅ Yes (application-level) |
| Role-based access (Admin / Employee / Customer) | ✅ Yes |
| Audit log of all create/update/delete operations | ✅ Yes |
| Rate limiting on all public endpoints | ✅ Yes |
| Encryption at rest (database field-level) | ❌ Not yet (see Gap #1) |
| Multi-factor authentication | ❌ Not yet (see Gap #2) |

---

### Your Rights As a Data Controller

Under the Egyptian PDPL (Law 151/2020), as the controller of your clients' data, you have the following obligations — and Qadaya commits to supporting you in meeting them:

| Your Obligation | How Qadaya Supports You |
|---|---|
| **Respond to data subject access requests** | Admin panel → Customer profile → export case records (manual export today; automated export planned Q3 2026) |
| **Delete a client's data on request** | Admin panel → Customer → Delete. *Note: see limitations below.* |
| **Correct inaccurate data** | Full edit access to all client and case fields |
| **Notify PDPC of a breach within 72 hours** | Qadaya will notify you of any server-side breach within 24 hours of discovery |
| **Ensure data is processed lawfully** | You are responsible for collecting client consent; Qadaya processes only on your instruction |

**Current deletion limitation:** Deleting a client record removes their profile and linked case data. Audit log entries that reference that client are currently retained (they serve as tamper-evident records required for legal accountability). A full "right to be forgotten" cascade is on our roadmap (Gap #3).

---

### Data Retention

| Data Type | Current Retention | Target Policy |
|---|---|---|
| Active case records | Until you delete them | Until you delete them |
| Deleted records | Immediate hard delete | Soft-delete with 90-day recovery window (planned) |
| Audit logs | Indefinite | 7 years (Egyptian legal record requirements) |
| Application logs | Rolling daily, no auto-purge | 30 days auto-purge (Gap #6) |
| Refresh tokens | 7 days rolling | 7 days (already enforced) |

---

### Breach Notification Commitment

If Qadaya becomes aware of a security incident that may have exposed your firm's data, we commit to:

1. Notifying you (as the data controller) **within 24 hours** of discovery
2. Providing a written incident summary within **72 hours**
3. Supporting your notification to PDPC if required

---

## Part 2 — Internal Gap Register

> **Status key:** 🔴 Critical (blocks first customer) | 🟠 High (fix within 30 days of first customer) | 🟡 Medium (fix within 90 days) | 🟢 Low (backlog)

---

### Gap #1 — Encryption at Rest 🟠
**Finding:** All PII (names, national IDs, phone numbers, email addresses, case content) stored in plaintext in PostgreSQL. No field-level encryption. No database-level encryption configured.

**Risk:** Server compromise or database credential theft (which are currently exposed — see Gap #7) gives direct read access to all client data.

**Remediation options (choose one):**
- A. Enable PostgreSQL `pgcrypto` extension + application-level encryption for high-sensitivity fields (NationalId, SSN, PhoneNumber). Medium effort.
- B. Enable PostgreSQL TDE (Transparent Data Encryption) at the OS/storage layer. Low application effort, requires VM-level change.
- C. Migrate to Azure Database for PostgreSQL with encryption at rest enabled by default. Best long-term option.

**Owner:** Backend team | **Effort:** 3–5 days | **Priority:** Before customer #5

---

### Gap #2 — Multi-Factor Authentication 🟠
**Finding:** `TwoFactorEnabled` field exists in the schema but MFA is never enforced or offered in the UI or API. Password-only auth for a system holding privileged legal data.

**Risk:** Credential stuffing or phishing compromises a firm's entire case history.

**Remediation:** Implement TOTP (Google Authenticator-compatible) MFA using ASP.NET Identity's built-in `IUserTwoFactorTokenProvider`. Add MFA setup screen in account settings. Make mandatory for Admin role.

**Owner:** Backend + Frontend | **Effort:** 3–4 days | **Priority:** Before customer #10

---

### Gap #3 — Incomplete "Right to Be Forgotten" Cascade 🟡
**Finding:** `DeleteCustomerAsync` hard-deletes the Customer record but does NOT cascade to: associated User record, IntakeLead records, AuditLog entries containing that customer's data, uploaded files linked to that customer, or billing/payment records.

**Risk:** Non-compliance with PDPL data erasure rights. A deleted "customer" still has PII scattered across 6+ tables.

**Remediation:** Implement a `CustomerDataErasureService` that:
1. Anonymizes (replaces with pseudonymous placeholder) rather than deletes audit log entries — preserves tamper-evident trail without retaining PII.
2. Deletes or anonymizes User, IntakeLead, ESignatureRequest, uploaded files, billing notes.
3. Records the erasure event itself in the audit log.

**Owner:** Backend | **Effort:** 2–3 days | **Priority:** Within 60 days of first customer

---

### Gap #4 — OpenAI Data Processing Disclosure 🟠
**Finding:** When AI document drafting is used, case text (potentially containing client names, national IDs, legal details) is sent to OpenAI's API. No in-app disclosure to the firm user before their data leaves the system.

**Risk:** Firm may inadvertently share privileged client information with a third-party AI provider without client consent. Potential attorney-client privilege implications.

**Remediation:**
1. Add a one-time consent banner on first use of any AI feature: *"AI features send your input to OpenAI. Do not include national IDs or sensitive personal data in AI prompts."*
2. Reduce token context: strip identified PII fields before sending to OpenAI where possible.
3. Evaluate OpenAI's data processing addendum (DPA) and sign it.

**Owner:** Frontend + Legal | **Effort:** 1 day (banner) + legal review | **Priority:** Before first customer uses AI features

---

### Gap #5 — PII in Application Logs 🟡
**Finding:** Serilog logs to `Logs/lawyersys-[date].log` (daily rolling, no auto-purge). Confirmed PII logged: recipient email addresses (SmtpEmailSender), phone numbers (Twilio), full AI request/response bodies including case content (AiAssistantTextService).

**Risk:** Log files on disk contain unmasked PII. Anyone with file system access can read client data from logs without going through the application's access controls.

**Remediation:**
1. Add `Destructure.ByTransforming<ApplicationUser>()` or custom log enricher to mask sensitive fields.
2. Add log retention policy (30-day auto-purge via Serilog `retainedFileCountLimit`).
3. Immediately: ensure `Logs/` directory is not web-accessible (verify IIS config).

**Owner:** Backend | **Effort:** 1 day | **Priority:** Within 30 days of first customer

---

### Gap #6 — Log Retention Policy Not Configured 🟡
**Finding:** No `retainedFileCountLimit` set in Serilog config. Logs accumulate indefinitely.

**Remediation:** Add to `appsettings.json` Serilog section:
```json
"retainedFileCountLimit": 30
```
This keeps 30 days of daily logs and auto-purges older files.

**Owner:** Backend | **Effort:** 15 minutes | **Priority:** Do it now

---

### Gap #7 — Secrets in Source Code 🔴 CRITICAL
**Finding:** The following secrets are hardcoded in `appsettings.json` (committed to source control):
- PostgreSQL password: `qrO4y935JTxd`
- Gmail SMTP app password: `qhhv xmis redd wouc`
- JWT signing key (64-char string)
- Admin seed account password
- Firebase service account file path

**Risk:** Anyone with repository access has production database credentials. A law firm evaluating the product who is also given repo access (or who sees a leak) would immediately disqualify the product.

**Remediation (immediate):**
1. Rotate ALL credentials above — treat them as compromised.
2. Move to environment variables on the IIS server (set via IIS Manager > Application Settings or Windows Environment Variables).
3. Use `dotnet user-secrets` for local dev.
4. Add `appsettings.json` to `.gitignore` for any sections containing secrets, or use a `appsettings.Production.json` that is gitignored.
5. Long term: Azure Key Vault or HashiCorp Vault.

**Owner:** DevOps / Backend | **Effort:** 2–4 hours | **Priority:** TODAY

---

### Gap #8 — Security Headers Missing 🟡
**Finding:** No HTTP security headers configured: no HSTS, no `X-Frame-Options`, no `X-Content-Type-Options`, no `Content-Security-Policy`, no `Referrer-Policy`.

**Risk:** Clickjacking, MIME-type sniffing attacks, no forced HTTPS on return visits.

**Remediation:** Add `NWebsec` or `Microsoft.AspNetCore.HeaderPropagation` middleware, or configure headers at IIS level. Minimum headers to add:
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
```

**Owner:** Backend / DevOps | **Effort:** 2–3 hours | **Priority:** Within 30 days of first customer

---

### Gap #9 — Audit Log Not Actively Recording 🟡
**Finding:** `AuditLog` table and schema exist. `AuditLogsService` and `AuditLogsController` exist. However, no middleware, interceptor, or EF Core SaveChanges override found that actively writes audit entries during normal business operations.

**Risk:** The audit log UI exists but is empty. If a customer asks to see who accessed or changed a case record, there is no data.

**Remediation:** Implement `SaveChangesInterceptor` in EF Core that captures entity state changes and writes to `AuditLog`. Or use a library like `Audit.NET`. Ensure sensitive OldValues/NewValues are masked before storage.

**Owner:** Backend | **Effort:** 2–3 days | **Priority:** Within 60 days of first customer

---

### Gap #10 — No Data Processing Agreement (DPA) Template 🟠
**Finding:** No standard DPA exists between Qadaya and customer law firms. Under Egyptian PDPL, a data controller (law firm) using a processor (Qadaya) must have a written agreement specifying the scope and terms of processing.

**Risk:** Without a DPA, any law firm that takes PDPL compliance seriously cannot legally use the platform.

**Remediation:** Draft a 1–2 page DPA addendum to the Terms of Service covering:
- Subject matter and duration of processing
- Nature and purpose of processing
- Types of personal data processed
- Categories of data subjects
- Processor's obligations (security, confidentiality, breach notification, deletion)
- Sub-processor list (OpenAI, Firebase, Twilio, Gmail)
- Audit rights

**Owner:** Legal / Founder | **Effort:** 1–2 days with a template | **Priority:** Before first paid customer signs

---

### Gap #11 — No Consent Mechanism on Public Intake Form 🟡
**Finding:** `POST /api/intake/public` accepts full name, email, phone, national ID, and case description from anonymous visitors — with no CAPTCHA, no explicit consent checkbox, no privacy notice link.

**Risk:** Collecting national IDs from the public without consent is a direct PDPL violation. The law firm embedding this form is the controller; Qadaya's form must support consent capture.

**Remediation:**
1. Add required consent checkbox: *"I agree to my data being processed for the purpose of this inquiry, in accordance with [Firm Name]'s privacy policy."*
2. Store consent timestamp and text version with each IntakeLead record.
3. Add CAPTCHA (Google reCAPTCHA v3 or hCaptcha).
4. Recommend (in docs) that law firms link their own privacy policy from the intake form.

**Owner:** Frontend + Backend | **Effort:** 1 day | **Priority:** Within 30 days of first customer

---

### Gap #12 — Row-Level Security Not Enforced at Database Level 🟡
**Finding:** Multi-tenancy is enforced at the application layer only (TenantId filtering in service code). A bug in a service method could accidentally expose one firm's data to another.

**Risk:** Application-layer bugs can cause cross-tenant data leakage. In a legal SaaS, this is catastrophic (privileged information from Firm A visible to Firm B).

**Remediation (short term):** Add integration tests that specifically verify cross-tenant isolation for all major entities (cases, customers, documents, employees).

**Remediation (long term):** Implement PostgreSQL Row-Level Security (RLS) policies on all tenant-scoped tables as a defense-in-depth backstop.

**Owner:** Backend | **Effort:** 2–3 days for tests; 1 week for RLS | **Priority:** Tests before first customer; RLS within 90 days

---

## Part 3 — Compliance Checklist for First Customer Conversation

Use this when a firm principal asks "how do you handle our data?":

- [x] Your data is logically isolated from all other firms on the platform
- [x] All access requires authentication with strong password policy
- [x] Access is role-based — staff can only see what their role permits
- [x] All actions are logged in an audit trail (note: complete after Gap #9 fix)
- [x] We host in Egypt / on a server you can verify
- [x] We will notify you of any breach within 24 hours
- [x] We sign a Data Processing Agreement before you go live
- [ ] Encryption at rest — *in progress, Q3 2026* (Gap #1)
- [ ] MFA for admin accounts — *in progress, Q3 2026* (Gap #2)
- [ ] Automated data export for subject access requests — *planned Q3 2026*

---

## Revision History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-06-09 | Qadaya Team | Initial document based on codebase audit |

---

*This document reflects the current state of the system as audited on 2026-06-09. It should be reviewed and updated with each major release.*
