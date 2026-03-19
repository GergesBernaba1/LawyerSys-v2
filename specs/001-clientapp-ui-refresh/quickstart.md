# Quickstart: ClientApp UI Refresh

## Objective

Implement and verify a bounded UI refresh for the ClientApp public entry pages, authentication pages, authenticated shell, and dashboard while preserving current routes, actions, and bilingual behavior.

## Implementation Focus

1. Audit the shared visual foundation in `LawyerSys/ClientApp/app/layout.tsx`, global styles, providers, and theme-related files.
2. Define or refine shared visual primitives for page headers, navigation, primary actions, cards, forms, and feedback states.
3. Apply the refreshed patterns to:
   - landing, about, and contact pages
   - login, register, forgot-password, and reset-password pages
   - authenticated shell layout and navigation treatment
   - dashboard page
4. Verify no business-critical actions or visible information groups are lost from refreshed pages.
5. Confirm Arabic/English and RTL/LTR presentation remains coherent.

## Validation Steps

1. Frontend build and type check:

```powershell
Set-Location "D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\ClientApp"
npm run build
```

2. Critical UI Playwright coverage:

```powershell
Set-Location "D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\ClientApp"
npm run test:e2e
```

3. Backend solution safety check if shared assets or hosting assumptions are touched:

```powershell
Set-Location "D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2"
dotnet build
```

## Review Checklist

- Landing and authentication pages share the same visual language.
- Authenticated shell and dashboard feel connected to the refreshed public experience.
- Primary actions are obvious on first view.
- Empty, loading, validation, and error states are visually consistent.
- Mobile layouts remain usable without blocked navigation or overlapping content.
- Arabic and English rendering both remain correct.

## Latest Validation

- `npm run build` completed successfully on 2026-03-20.
- `npx playwright test tests/ui-refresh.spec.ts tests/core-flows.spec.ts tests/sidebar.spec.ts --project=chromium` passed on 2026-03-20.
