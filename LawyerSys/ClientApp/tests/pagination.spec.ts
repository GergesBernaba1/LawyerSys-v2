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
  await expect(page.getByRole('navigation', { name: 'pagination navigation' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Go to page 2' })).toBeVisible();

  // items from page 1 shown
  await expect(page.getByText('1')).toBeVisible();
  await page.click('button[aria-label="Go to page 2"]');

  // items from page 2 shown
  await expect(page.getByText('6')).toBeVisible();
});

// Judicial documents pagination
const judicialPage1 = { items: Array.from({ length: 5 }, (_, i) => ({ id: i+1, docType: 'Type', docNum: i+1 })), totalCount: 12, page: 1, pageSize: 5, totalPages: 3 };
const judicialPage2 = { items: Array.from({ length: 5 }, (_, i) => ({ id: i+6, docType: 'Type', docNum: i+6 })), totalCount: 12, page: 2, pageSize: 5, totalPages: 3 };

test('Judicial documents page shows pagination and loads pages', async ({ page }) => {
  await page.route('**/api/JudicialDocuments?page=1&pageSize=5**', route => route.fulfill({ status: 200, body: JSON.stringify(judicialPage1), headers: { 'Content-Type': 'application/json' } }));
  await page.route('**/api/JudicialDocuments?page=2&pageSize=5**', route => route.fulfill({ status: 200, body: JSON.stringify(judicialPage2), headers: { 'Content-Type': 'application/json' } }));

  await page.addInitScript(() => localStorage.setItem('lawyersys-token', 'eyJ.dummy.signature'));
  await page.goto('/judicial');

  await expect(page.getByRole('navigation', { name: 'pagination navigation' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Go to page 2' })).toBeVisible();

  await expect(page.getByText('1')).toBeVisible();
  await page.click('button[aria-label="Go to page 2"]');
  await expect(page.getByText('6')).toBeVisible();
});

// Admin tasks pagination
const tasksPage1 = { items: Array.from({ length: 5 }, (_, i) => ({ id: i+1, taskName: `T${i+1}` })), totalCount: 12, page: 1, pageSize: 5, totalPages: 3 };
const tasksPage2 = { items: Array.from({ length: 5 }, (_, i) => ({ id: i+6, taskName: `T${i+6}` })), totalCount: 12, page: 2, pageSize: 5, totalPages: 3 };

test('Admin tasks page shows pagination and loads pages', async ({ page }) => {
  await page.route('**/api/AdminTasks?page=1&pageSize=5**', route => route.fulfill({ status: 200, body: JSON.stringify(tasksPage1), headers: { 'Content-Type': 'application/json' } }));
  await page.route('**/api/AdminTasks?page=2&pageSize=5**', route => route.fulfill({ status: 200, body: JSON.stringify(tasksPage2), headers: { 'Content-Type': 'application/json' } }));

  await page.addInitScript(() => localStorage.setItem('lawyersys-token', 'eyJ.dummy.signature'));
  await page.goto('/tasks');

  await expect(page.getByRole('navigation', { name: 'pagination navigation' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Go to page 2' })).toBeVisible();

  await expect(page.getByText('1')).toBeVisible();
  await page.click('button[aria-label="Go to page 2"]');
  await expect(page.getByText('6')).toBeVisible();
});