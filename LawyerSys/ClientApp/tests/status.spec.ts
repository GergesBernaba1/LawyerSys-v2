import { test, expect } from '@playwright/test';

const caseFull = {
  Case: { Id: 1, Code: 123, InvitionsStatment: '', InvitionType: 'T', InvitionDate: '2026-02-17', TotalAmount: 0, Notes: '', Status: 0 },
  Customers: [],
  Contenders: [],
  Courts: [],
  Employees: [],
  Sitings: [],
  Files: [],
  StatusHistory: []
};

test('Case detail shows status and allows change for employee/admin', async ({ page }) => {
  await page.route('**/api/cases/123/full', route => route.fulfill({ status: 200, body: JSON.stringify(caseFull), headers: { 'Content-Type': 'application/json' } }));
  await page.route('**/api/Cases/123/status', route => route.fulfill({ status: 200, body: JSON.stringify({ id: 1, code: 123, status: 1 }), headers: { 'Content-Type': 'application/json' } }));

  // create a valid-looking token that contains an Employee role
  const fakeToken = (payload: Record<string, any>) => {
    const header = { alg: 'HS256', typ: 'JWT' };
    const b64 = (obj: any) => Buffer.from(JSON.stringify(obj)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
    return `${b64(header)}.${b64(payload)}.signature`;
  };
  const token = fakeToken({ role: 'Employee', unique_name: 'emp@example.com', email: 'emp@example.com' });
  await page.addInitScript((t) => { localStorage.setItem('lawyersys-token', t); }, token);
  await page.goto('/cases/123');

  // initial status
  await expect(page.getByText('New')).toBeVisible();

  // change status to In Progress
  await page.getByRole('button', { name: 'Status' }).click();
  await page.getByRole('option', { name: 'In Progress' }).click();

  // after change, UI should show updated localized label
  await expect(page.getByText('In Progress')).toBeVisible();
});