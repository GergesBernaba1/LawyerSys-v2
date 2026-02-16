import { test, expect } from '@playwright/test';

const samplePage1 = { items: Array.from({ length: 5 }, (_, i) => ({ id: i+1, code: i+1 })), totalCount: 12, page: 1, pageSize: 5, totalPages: 3 };
const samplePage2 = { items: Array.from({ length: 5 }, (_, i) => ({ id: i+6, code: i+6 })), totalCount: 12, page: 2, pageSize: 5, totalPages: 3 };

test('Cases page shows pagination and loads pages', async ({ page }) => {
  // intercept API calls and return paged responses
  await page.route('**/api/Cases?page=1&pageSize=5**', route => route.fulfill({ status: 200, body: JSON.stringify(samplePage1), headers: { 'Content-Type': 'application/json' } }));
  await page.route('**/api/Cases?page=2&pageSize=5**', route => route.fulfill({ status: 200, body: JSON.stringify(samplePage2), headers: { 'Content-Type': 'application/json' } }));

  await page.addInitScript(() => localStorage.setItem('lawyersys-token', 'eyJ.dummy.signature'));
  await page.goto('/cases');

  // pagination control should be visible
  await expect(page.getByRole('navigation')).toBeVisible();
  await expect(page.getByRole('button', { name: '2' })).toBeVisible();

  // items from page 1 shown
  await expect(page.getByText('1')).toBeVisible();
  await page.click('button[aria-label="Go to page 2"]');

  // items from page 2 shown
  await expect(page.getByText('6')).toBeVisible();
});