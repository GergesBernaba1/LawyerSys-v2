import { test, expect } from '@playwright/test';

function fakeToken(payload: Record<string, any>) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const b64 = (obj: any) => Buffer.from(JSON.stringify(obj)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${b64(header)}.${b64(payload)}.signature`;
}

test.describe('RBAC UI', () => {
  test('Admin sees create buttons (cases & customers)', async ({ page }) => {
    const token = fakeToken({ role: 'Admin', unique_name: 'admin@example.com', email: 'admin@example.com' });
    await page.addInitScript((t) => { localStorage.setItem('lawyersys-token', t); }, token);
    await page.goto('/cases');

    await expect(page.getByRole('button', { name: /New Case/i })).toBeVisible();


  });

  test('Employee sees case controls but not customer-create', async ({ page }) => {
    const token = fakeToken({ role: 'Employee', unique_name: 'emp@example.com' });
    await page.addInitScript((t) => { localStorage.setItem('lawyersys-token', t); }, token);

    await page.goto('/cases');
    await expect(page.getByRole('button', { name: /New Case/i })).toBeVisible();

    await page.goto('/customers');
    await expect(page.getByRole('button', { name: /Create New Customer/i })).toHaveCount(0);
  });

  test('Customer does not see create buttons', async ({ page }) => {
    const token = fakeToken({ role: 'Customer', unique_name: 'cust@example.com' });
    await page.addInitScript((t) => { localStorage.setItem('lawyersys-token', t); }, token);

    await page.goto('/cases');
    await expect(page.getByRole('button', { name: /New Case/i })).toHaveCount(0);

    await page.goto('/customers');
    await expect(page.getByRole('button', { name: /Create New Customer/i })).toHaveCount(0);
  });
});