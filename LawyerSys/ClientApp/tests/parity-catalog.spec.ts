import { test, expect } from '@playwright/test'

test('parity roadmap page heading is visible', async ({ page }) => {
  await page.goto('/parity-roadmap')
  await expect(page.getByRole('heading', { name: /parity roadmap/i })).toBeVisible()
})
