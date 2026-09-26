import { test, expect } from '@playwright/test';

test('widget designs switch shape and theme, persist, and open the selected floating design', async ({ page, context }) => {
  await page.goto('/widgets.html');
  const preview = page.locator('#widget-preview');
  const initial = Number((await preview.locator('[data-value]').textContent()).replaceAll(',', ''));
  await expect.poll(async () => Number((await preview.locator('[data-value]').textContent()).replaceAll(',', ''))).toBeLessThan(initial);
  await page.getByRole('button', { name: '정사각형', exact: true }).click();
  await page.getByRole('button', { name: '라이트', exact: true }).click();
  await expect(preview.locator('[data-unit]')).toHaveText('일');
  await page.reload();
  await expect(preview.locator('article')).toHaveClass(/widget-square widget-light/);
  const opened = context.waitForEvent('page');
  await page.getByRole('button', { name: '이 디자인으로 작은 창 열기' }).click();
  const popup = await opened;
  await expect(popup.locator('article')).toHaveClass(/widget-square widget-light/);
  await expect(popup.locator('[data-value]')).toHaveText(await preview.locator('[data-value]').textContent());
  await page.getByRole('button', { name: '한 줄형', exact: true }).click();
  await expect(popup.locator('article')).toHaveClass(/widget-slim widget-light/);
  await expect(popup.locator('[data-unit]')).toHaveText('초');
  await popup.getByRole('button', { name: '작은 창 닫기' }).click();
  await page.setViewportSize({ width: 320, height: 800 });
  await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  const numberFits = await preview.locator('.widget-number').evaluate(el => el.scrollWidth <= el.clientWidth);
  expect(numberFits).toBe(true);
});

test('widget page keeps its own design and live preview after offline reload', async ({ page, context }) => {
  await page.goto('/widgets.html');
  await page.evaluate(() => navigator.serviceWorker.ready);
  await expect.poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller))).toBe(true);
  await context.setOffline(true);
  await page.reload();
  await expect(page).toHaveTitle('위젯 — 메멘토모리');
  await expect(page.locator('#widget-preview [data-value]')).not.toHaveText('—');
  await page.getByRole('button', { name: '정사각형', exact: true }).click();
  await expect(page.locator('#widget-preview [data-unit]')).toHaveText('일');
});

test('preview resizes by dragging and keeps custom bounds when changing theme', async ({ page }) => {
  await page.setViewportSize({ width: 1100, height: 1000 });
  await page.goto('/widgets.html');
  const widget = page.locator('#widget-preview article');
  const bounds = await widget.boundingBox();
  await page.mouse.move(bounds.x + bounds.width - 4, bounds.y + bounds.height - 4);
  await page.mouse.down();
  await page.mouse.move(bounds.x + bounds.width - 104, bounds.y + bounds.height + 175, { steps: 15 });
  await page.mouse.up();
  await expect(widget).toHaveAttribute('data-layout', 'portrait');
  const resized = await widget.boundingBox();
  expect(resized.height).toBeGreaterThan(bounds.height + 100);
  await expect(widget.locator('[data-unit]')).toHaveText('초');
  await page.getByRole('button', { name: '라이트', exact: true }).click();
  const afterTheme = await widget.boundingBox();
  expect(Math.abs(resized.width - afterTheme.width)).toBeLessThan(2);
  expect(Math.abs(resized.height - afterTheme.height)).toBeLessThan(2);
  expect(await widget.locator('.widget-number').evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
  await page.screenshot({ path: '../../artifacts/resizable-web-widget.png' });
});
