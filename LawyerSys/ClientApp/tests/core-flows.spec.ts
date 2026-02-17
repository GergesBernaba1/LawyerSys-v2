import { test, expect } from '@playwright/test';

function fakeToken(payload: Record<string, any>) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const b64 = (obj: any) => Buffer.from(JSON.stringify(obj)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${b64(header)}.${b64(payload)}.signature`;
}

test('login flow works with API token response', async ({ page }) => {
  const token = fakeToken({ role: 'Admin', unique_name: 'admin', exp: Math.floor(Date.now() / 1000) + 3600 });

  await page.route('**/api/Account/login', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ token, expires: new Date(Date.now() + 3600_000).toISOString() })
    });
  });

  await page.goto('/login');
  await page.getByLabel(/username/i).fill('admin');
  await page.getByLabel(/password/i).fill('Admin@1234');
  await page.getByRole('button', { name: /login|sign in/i }).click();

  await expect(page).toHaveURL(/\/$/);
});

test('case creation flow and billing pages are functional', async ({ page }) => {
  const token = fakeToken({ role: 'Admin', unique_name: 'admin', exp: Math.floor(Date.now() / 1000) + 3600 });
  await page.addInitScript((t) => localStorage.setItem('lawyersys-token', t), token);

  let caseCreated = false;
  await page.route('**/api/Cases**', route => {
    if (route.request().method() === 'POST') {
      caseCreated = true;
      return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({ id: 1, code: 1001, notes: 'e2e' }) });
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ items: [], totalCount: 0, page: 1, pageSize: 10 }) });
  });

  await page.route('**/api/Courts**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/Customers**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/Contenders**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/cases/1001/**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) }));

  await page.goto('/cases');
  await page.getByRole('button', { name: /new case/i }).click();
  await page.getByLabel(/code/i).first().fill('1001');
  await page.getByLabel(/notes/i).last().fill('e2e case');
  await page.getByRole('button', { name: /create/i }).last().click();
  await expect.poll(() => caseCreated).toBeTruthy();

  await page.route('**/api/Billing/payments**', route => {
    if (route.request().method() === 'POST') {
      return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({ id: 1, amount: 10 }) });
    }
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
  });
  await page.route('**/api/Billing/receipts**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/Billing/summary**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ totalPayments: 0, totalReceipts: 0, balance: 0 }) }));

  await page.goto('/billing');
  await expect(page.getByText(/billing/i)).toBeVisible();
});

test('CRUD pages load without API errors (smoke)', async ({ page }) => {
  const token = fakeToken({ role: 'Admin', unique_name: 'admin', exp: Math.floor(Date.now() / 1000) + 3600 });
  await page.addInitScript((t) => localStorage.setItem('lawyersys-token', t), token);

  await page.route('**/api/**', route => {
    const method = route.request().method();
    if (method === 'POST') return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({ id: 1 }) });
    if (method === 'PUT') return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) });
    if (method === 'DELETE') return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) });
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
  });

  const pages = ['/customers', '/employees', '/courts', '/governments', '/contenders', '/sitings', '/consultations', '/judicial', '/tasks', '/files', '/legacyusers', '/caserelations'];

  for (const path of pages) {
    await page.goto(path);
    await expect(page.getByRole('heading').first()).toBeVisible();
  }
});
