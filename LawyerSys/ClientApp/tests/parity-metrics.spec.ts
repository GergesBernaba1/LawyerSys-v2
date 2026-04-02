import { test, expect } from '@playwright/test'

test('parity metrics editor visible', async ({ page }) => {
  await page.goto('/parity-roadmap')
  await expect(page.getByText(/metrics/i)).toBeVisible()
})
