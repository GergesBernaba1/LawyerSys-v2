import { test, expect } from '@playwright/test';

function fakeToken(payload: Record<string, any>) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const b64 = (obj: any) => Buffer.from(JSON.stringify(obj)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${b64(header)}.${b64(payload)}.signature`;
}

test('sidebar default expanded and toggle works on dashboard shell', async ({ page }) => {
  const token = fakeToken({
    role: 'Admin',
    unique_name: 'admin',
    fullName: 'Admin User',
    email: 'admin@example.com',
    exp: Math.floor(Date.now() / 1000) + 3600,
  });

  await page.addInitScript((t) => localStorage.setItem('lawyersys-token', t), token);
  await page.addInitScript(() => localStorage.setItem('i18nextLng', 'en'));
  await page.route('**/api/Account/me', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ tenantId: 1, tenantName: 'Office' }) }));
  await page.route('**/api/Dashboard/analytics', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({
      totals: { cases: 3, customers: 2, employees: 1, files: 5 },
      trends: { casesChangePercent: 4, revenueThisMonth: 1200, revenueChangePercent: 6 },
      alerts: { upcomingHearings: 1, overdueTasks: 0 },
    }),
  }));
  await page.route('**/api/Cases?page=1&pageSize=5', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ items: [] }) }));

  await page.goto('/dashboard');

  await expect(page.getByRole('heading', { name: /لوحة التحكم|dashboard/i })).toBeVisible({ timeout: 30000 });

  const headerToggle = page.locator('button[aria-label="toggle sidebar"]');
  await expect(headerToggle).toBeVisible();
  await headerToggle.click();

  const saved = await page.evaluate(() => localStorage.getItem('layout.sidebarCollapsed'));
  expect(saved).toBe('true');
});
