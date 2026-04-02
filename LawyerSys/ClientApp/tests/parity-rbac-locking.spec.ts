import { test, expect } from '@playwright/test'

test('parity locking controls visible', async ({ page }) => {
  await page.goto('/parity-roadmap')
  await expect(page.getByText(/lock/i)).toBeVisible()
})
