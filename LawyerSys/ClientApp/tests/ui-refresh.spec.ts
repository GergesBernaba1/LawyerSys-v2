import { test, expect } from '@playwright/test';

function fakeToken(payload: Record<string, any>) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const b64 = (obj: any) => Buffer.from(JSON.stringify(obj)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${b64(header)}.${b64(payload)}.signature`;
}

const landingPayload = {
  systemName: 'Qadaya',
  tagline: 'Legal work, client intake, and firm operations in one controlled workspace.',
  heroTitle: 'Run your legal practice with clarity.',
  heroSubtitle: 'One operating system for cases, customers, billing, and administration.',
  primaryButtonText: 'Create tenant',
  primaryButtonUrl: '/register',
  secondaryButtonText: 'Sign in',
  secondaryButtonUrl: '/login',
  aboutTitle: 'Built for disciplined legal teams',
  aboutDescription: 'Bring legal operations into one shared workspace.',
  aboutPageTitle: 'About Qadaya',
  aboutPageSubtitle: 'A legal operations platform for modern offices.',
  aboutPageDescription: 'A structured environment for legal work.',
  aboutPageMissionTitle: 'Mission',
  aboutPageMissionDescription: 'Give offices better coordination.',
  aboutPageVisionTitle: 'Vision',
  aboutPageVisionDescription: 'Make legal operations more visible.',
  contactPageTitle: 'Contact our team',
  contactPageSubtitle: 'Commercial and onboarding support.',
  contactPageDescription: 'Reach the team through the channels below.',
  contactEmail: 'team@example.com',
  contactPhone: '+966500000000',
  contactAddress: 'Riyadh',
  contactWorkingHours: 'Sun-Thu 9 to 6',
  features: [
    { title: 'Structured operations', description: 'Track cases and tasks.', iconKey: 'automation' },
    { title: 'Client coordination', description: 'Keep clients updated.', iconKey: 'collaboration' },
    { title: 'Admin visibility', description: 'Control your office.', iconKey: 'insight' },
  ],
};

test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('i18nextLng', 'en'));
  await page.route('**/api/LandingPage', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(landingPayload) }));
  await page.route('**/api/SubscriptionPackages/public', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
  await page.route('**/api/Tenants/public-partners', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) }));
});

test('public entry pages expose refreshed hierarchy and calls to action', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('button', { name: /Create tenant/i }).first()).toBeVisible({ timeout: 30000 });
  await expect(page.getByRole('button', { name: /Book a demo/i }).first()).toBeVisible({ timeout: 30000 });
  await expect(page.getByText(/support@qadaya.app|team@example.com/i).first()).toBeVisible({ timeout: 30000 });

  await page.goto('/about-us');
  await expect(page.getByText(/Qadaya/i)).toBeVisible({ timeout: 30000 });

  await page.goto('/contact-us');
  await expect(page.getByText(/support@qadaya.app|team@example.com/i).first()).toBeVisible({ timeout: 30000 });
});

test('dashboard and authentication screens keep refreshed presentation', async ({ page }) => {
  const token = fakeToken({
    role: 'Admin',
    unique_name: 'admin',
    fullName: 'Admin User',
    email: 'admin@example.com',
    exp: Math.floor(Date.now() / 1000) + 3600,
  });

  await page.route('**/api/Account/me', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ tenantId: 1, tenantName: 'Office' }) }));
  await page.route('**/api/Dashboard/analytics', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({
      totals: { cases: 12, customers: 8, employees: 4, files: 16 },
      trends: { casesChangePercent: 8, revenueThisMonth: 4500, revenueChangePercent: 12 },
      alerts: { upcomingHearings: 3, overdueTasks: 2 },
    }),
  }));
  await page.route('**/api/Cases?page=1&pageSize=5', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ items: [] }) }));

  await page.goto('/login');
  await expect(page.locator('#userName')).toBeVisible({ timeout: 30000 });
  await expect(page.getByText(/LEGAL OPERATIONS PLATFORM|Qadaya/i).first()).toBeVisible({ timeout: 30000 });

  await page.addInitScript((t) => localStorage.setItem('lawyersys-token', t), token);
  await page.goto('/dashboard');
  await expect(page.getByRole('heading', { name: /Dashboard/i })).toBeVisible({ timeout: 30000 });
  await expect(page.getByRole('heading', { name: /Welcome back|Admin User/i }).first()).toBeVisible({ timeout: 30000 });
  await expect(page.getByText(/Quick Actions/i)).toBeVisible({ timeout: 30000 });
});
