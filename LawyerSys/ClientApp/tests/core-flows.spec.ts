import { test, expect } from '@playwright/test';
import { fakeToken } from './helpers';

test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('i18nextLng', 'en');
  });
});

test('login flow works with API token response', async ({ page }) => {
  const token = fakeToken({ role: 'Admin', unique_name: 'admin', exp: Math.floor(Date.now() / 1000) + 3600 });

  await page.route('**/api/Account/me', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ tenantId: 1, tenantName: 'Office' })
    });
  });

  await page.route('**/api/Dashboard/analytics', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        totals: { cases: 0, customers: 0, employees: 0, files: 0 },
        trends: { casesChangePercent: 0, revenueThisMonth: 0, revenueChangePercent: 0 },
        alerts: { upcomingHearings: 0, overdueTasks: 0 }
      })
    });
  });

  await page.route('**/api/Cases?page=1&pageSize=5', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ items: [] })
    });
  });

  await page.route('**/api/Account/login', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ token, expires: new Date(Date.now() + 3600_000).toISOString() })
    });
  });

  await page.goto('/login');
  await expect(page.locator('#userName')).toBeVisible({ timeout: 30000 });
  await page.locator('#userName').fill('admin');
  await page.locator('#password').fill('Admin@1234');
  await page.getByRole('button', { name: /login|sign in/i }).click();

  await expect(page).toHaveURL(/\/dashboard$/);
});

test('case creation flow submits correct POST and shows new case', async ({ page }) => {
  const token = fakeToken({ role: 'Admin', unique_name: 'admin', exp: Math.floor(Date.now() / 1000) + 3600 });
  // nosec: test-only localStorage seeding via Playwright addInitScript, not reachable by untrusted input
  await page.addInitScript((t) => localStorage.setItem('lawyersys-token', t), token);
  await page.route('**/api/Account/me', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ tenantId: 1, tenantName: 'Office' }) }));
  await page.route('**/api/Dashboard/analytics', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ totals: { cases: 0, customers: 0, employees: 0, files: 0 }, trends: { casesChangePercent: 0, revenueThisMonth: 0, revenueChangePercent: 0 }, alerts: { upcomingHearings: 0, overdueTasks: 0 } }) }));
  let createdCaseRequest: any = null;
  let cases: any[] = [];

  await page.route('**/api/Cases*', async route => {
    const request = route.request();
    if (request.method() === 'POST') {
      createdCaseRequest = request;
      const newCase = { id: 1001, code: 1234, invitionsStatment: '', invitionType: '', invitionDate: '', totalAmount: 0, notes: 'Test case notes', status: 0 };
      cases = [newCase];
      await route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify(newCase) });
      return;
    }
    await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ items: cases, totalCount: cases.length, page: 1, pageSize: 10 }) });
  });

  await page.route('**/api/Courts**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/Customers**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/Contenders**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/cases/1001/**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) }));

  await page.goto('/cases');
  await expect(page.getByText(/Cases Management|إدارة القضايا/i)).toBeVisible({ timeout: 30000 });

  await page.getByRole('button', { name: /new case|create first/i }).click();
  await expect(page.getByRole('heading', { name: /create new/i })).toBeVisible({ timeout: 15000 });
  await page.getByLabel('Code').fill('1234');
  await page.getByLabel(/Notes|notes/i).fill('Test case notes');
  await page.getByRole('button', { name: /create/i }).first().click();

  await expect(createdCaseRequest).not.toBeNull();
  expect(createdCaseRequest.method()).toBe('POST');
  expect(createdCaseRequest.url()).toContain('/api/Cases');

  const payload = JSON.parse(createdCaseRequest.postData() ?? '{}');
  expect(payload.code || payload.CaseCode || payload.name).toBeDefined();
  expect(payload.code || payload.CaseCode || payload.name).toBe('1234');
  expect(payload.notes).toBe('Test case notes');

  await expect(page.getByText('1234')).toBeVisible({ timeout: 30000 });
});

test('billing page loads without errors', async ({ page }) => {
  const token = fakeToken({ role: 'Admin', unique_name: 'admin', exp: Math.floor(Date.now() / 1000) + 3600 });
  // nosec: test-only localStorage seeding via Playwright addInitScript, not reachable by untrusted input
  await page.addInitScript((t) => localStorage.setItem('lawyersys-token', t), token);
  await page.route('**/api/Account/me', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ tenantId: 1, tenantName: 'Office' }) }));
  await page.route('**/api/Billing/payments**', route => {
    if (route.request().method() === 'POST') {
      return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({ id: 1, amount: 10 }) });
    }
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
  });
  await page.route('**/api/Billing/receipts**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/Billing/summary**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ totalPayments: 0, totalReceipts: 0, balance: 0 }) }));

  await page.goto('/billing');
  await expect(page.getByRole('heading', { name: /billing/i }).first()).toBeVisible();
  await expect(page.locator('body')).not.toContainText(/error|something went wrong|unhandled/i);
});

test('CRUD pages load without API errors (smoke)', async ({ page }) => {
  const token = fakeToken({ role: 'Admin', unique_name: 'admin', exp: Math.floor(Date.now() / 1000) + 3600 });
  // nosec: test-only localStorage seeding via Playwright addInitScript, not reachable by untrusted input
  await page.addInitScript((t) => localStorage.setItem('lawyersys-token', t), token);
  await page.route('**/api/Account/me', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ tenantId: 1, tenantName: 'Office' }) }));

  await page.route('**/api/**', route => {
    const method = route.request().method();
    if (method === 'POST') return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({ id: 1 }) });
    if (method === 'PUT') return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) });
    if (method === 'DELETE') return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) });
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
  });

  const pages = ['/customers', '/employees', '/courts', '/governments', '/contenders', '/sitings', '/consultations', '/judicial', '/tasks', '/files', '/users', '/caserelations'];

  for (const path of pages) {
    await page.goto(path);
    await expect(page.getByRole('heading').first()).toBeVisible({ timeout: 30000 });
    await expect(page.locator('body')).not.toContainText(/error|something went wrong|unhandled/i);
  }
});
