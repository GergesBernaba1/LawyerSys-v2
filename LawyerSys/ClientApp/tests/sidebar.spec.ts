import { test, expect } from '@playwright/test';

test('sidebar default expanded and toggle works', async ({ page }) => {
  await page.goto('/');

  // Wait for the layout to render
  await expect(page.locator('text=LawyerSys')).toBeVisible({ timeout: 5000 });
  await page.screenshot({ path: 'sidebar-expanded.png', fullPage: true });

  // Click header toggle
  const headerToggle = page.locator('button[aria-label="toggle sidebar"]');
  await expect(headerToggle).toBeVisible();
  await headerToggle.click();

  // After collapse, the 'LawyerSys' label should be hidden
  await expect(page.locator('text=LawyerSys')).toHaveCount(0);
  await page.screenshot({ path: 'sidebar-collapsed.png', fullPage: true });

  // Verify localStorage updated
  const saved = await page.evaluate(() => localStorage.getItem('layout.sidebarCollapsed'));
  expect(saved).toBe('true');

  // Toggle back using the sidebar button when visible
  const sideToggle = page.locator('aside button[aria-label="toggle sidebar"]').first();
  if (await sideToggle.count() > 0) {
    await sideToggle.click();
    await expect(page.locator('text=LawyerSys')).toBeVisible();
    await page.screenshot({ path: 'sidebar-restored.png', fullPage: true });
  }
});
