import { test, expect } from '@playwright/test';

async function setupProfile(page, birthday = '1990-04-15', years = '83.7') {
  await page.getByRole('button', { name: '나의 시간으로 바꾸기' }).click();
  await page.getByLabel('생년월일', { exact: true }).fill(birthday);
  await page.getByRole('spinbutton', { name: /기준 수명/ }).fill(years);
  await page.getByRole('button', { name: '나의 시간 만나기' }).click();
}

test('profile, timer, intention and display preference persist; reset clears them', async ({ page }) => {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/');
  await expect(page.locator('#demo-notice')).toBeVisible();
  await setupProfile(page);
  await expect(page.locator('#demo-notice')).toBeHidden();
  const initial = Number((await page.locator('#remaining-number').textContent()).replaceAll(',', ''));
  await expect.poll(async () => Number((await page.locator('#remaining-number').textContent()).replaceAll(',', ''))).toBeLessThan(initial);
  await page.getByLabel('오늘 아끼고 싶은 한 가지').fill('부모님께 전화하기');
  await page.getByRole('button', { name: '기억하기' }).click();
  await page.getByRole('button', { name: '일', exact: true }).click();
  await page.reload();
  await expect(page.locator('#remaining-unit')).toHaveText('일');
  await expect(page.getByLabel('오늘 아끼고 싶은 한 가지')).toHaveValue('부모님께 전화하기');
  await expect(page.locator('#birth-label')).toContainText('1990.04.15');
  await page.getByRole('button', { name: '나의 시간 설정' }).click();
  await page.getByRole('button', { name: '이 기기의 기록 지우기' }).click();
  await page.getByRole('button', { name: '모두 지우기' }).click();
  await expect(page.locator('#demo-notice')).toBeVisible();
  await expect(page.getByLabel('오늘 아끼고 싶은 한 가지')).toHaveValue('');
  expect(errors).toEqual([]);
});

test('invalid profiles and passing the reference show appropriate messages', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '나의 시간으로 바꾸기' }).click();
  await page.getByRole('button', { name: '나의 시간 만나기' }).click();
  await expect(page.locator('#profile-error')).toContainText('생년월일');
  await page.getByLabel('생년월일', { exact: true }).fill('2099-01-01');
  await page.getByRole('button', { name: '나의 시간 만나기' }).click();
  await expect(page.locator('#profile-error')).toContainText('이전');
  await page.getByLabel('생년월일', { exact: true }).fill('1940-01-01');
  await page.getByRole('spinbutton', { name: /기준 수명/ }).fill('80');
  await page.getByRole('button', { name: '나의 시간 만나기' }).click();
  await expect(page.locator('#remaining-number')).toHaveText('0');
  await expect(page.locator('#passed-message')).toBeVisible();
});

test('mobile layout fits the screen, focus mode can be exited, personal text is safe', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await setupProfile(page);
  await page.getByLabel('오늘 아끼고 싶은 한 가지').fill('<img src=x onerror=alert(1)>');
  await page.getByRole('button', { name: '기억하기' }).click();
  await page.getByRole('button', { name: '곁에 두기' }).click();
  await page.getByRole('button', { name: '집중 화면 열기' }).click();
  await expect(page.locator('body')).toHaveClass('focus-mode');
  await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.keyboard.press('Escape');
  await expect(page.locator('body')).not.toHaveClass('focus-mode');
  await expect(page.locator('img')).toHaveCount(0);
});

test('production app and saved profile load offline', async ({ page, context }) => {
  await page.goto('/');
  await setupProfile(page);
  await page.evaluate(() => navigator.serviceWorker.ready);
  await expect.poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller))).toBe(true);
  await context.setOffline(true);
  await page.reload();
  await expect(page.locator('#birth-label')).toContainText('1990.04.15');
  await expect(page.locator('#remaining-number')).not.toHaveText('—');
  await context.setOffline(false);
});

test('desktop picture-in-picture displays the same live countdown', async ({ page, context }) => {
  await page.goto('/');
  await setupProfile(page);
  await page.getByRole('button', { name: '곁에 두기' }).click();
  const popupPromise = context.waitForEvent('page');
  await page.getByRole('button', { name: '작은 창 띄우기' }).click();
  const popup = await popupPromise;
  await expect(popup.locator('#pip-value')).not.toHaveText('');
  await expect(popup.locator('[data-description]')).toContainText('개인의 수명 예측이 아닙니다');
  const initial = Number((await popup.locator('#pip-value').textContent()).replaceAll(',', ''));
  await expect.poll(async () => Number((await popup.locator('#pip-value').textContent()).replaceAll(',', ''))).toBeLessThan(initial);
  await popup.getByRole('button', { name: '작은 창 닫기' }).click();
  await expect.poll(() => popup.isClosed()).toBe(true);
});

test('settings transfer imports Mac data only after confirmation and exports it back', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '나의 시간 설정', exact: true }).click();
  const settings = { app: 'mementomori', version: 1, state: { profile: { birthday: '1990-04-15', years: 85 }, mode: 'days' }, widget: { variant: 'slim', theme: 'light' } };
  await page.locator('#settings-file').setInputFiles({ name: 'settings.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(settings)) });
  await expect(page.locator('#import-confirmation')).toBeVisible();
  await expect(page.locator('#birthday')).toHaveValue('');
  await page.locator('#confirm-import').click();
  await expect(page.locator('#birthday')).toHaveValue('1990-04-15');
  await expect(page.locator('#remaining-unit')).toHaveText('일');
  const downloadPromise = page.waitForEvent('download');
  await page.locator('#export-settings').click();
  const download = await downloadPromise;
  const { readFile } = await import('node:fs/promises');
  expect(JSON.parse(await readFile(await download.path(), 'utf8'))).toEqual(settings);
  await page.reload();
  await expect(page.locator('#remaining-unit')).toHaveText('일');
  await page.getByRole('button', { name: '나의 시간 설정', exact: true }).click();
  await page.locator('#settings-file').setInputFiles({ name: 'broken.json', mimeType: 'application/json', buffer: Buffer.from('{}') });
  await expect(page.locator('#transfer-message')).toContainText('메멘토모리 설정 파일이 아니거나');
  await expect(page.locator('#birthday')).toHaveValue('1990-04-15');
});
