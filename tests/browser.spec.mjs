import { test, expect } from '@playwright/test';
test('the farmhouse loads, starts, shoots and pauses without browser errors', async ({ page }) => {
  const errors = [];
  page.on('pageerror', error => errors.push(String(error)));
  await page.goto('/');
  await expect(page.locator('#overlayTitle')).toContainText('شکار سیبیل');
  await page.evaluate(() => document.fonts.ready);
  const font = await page.locator('body').evaluate(el => getComputedStyle(el).fontFamily);
  expect(font).toContain('Noto Sans Arabic');
  const fontStatus = await page.evaluate(async () => {
    await document.fonts.load('500 14px "Noto Sans Arabic"', 'شکار سیبیل');
    await document.fonts.ready;
    const faces = [...document.fonts].filter(face => face.family.replace(/['"]/g, '') === 'Noto Sans Arabic');
    return { count: faces.length, loaded: faces.some(face => face.status === 'loaded') };
  });
  expect(fontStatus.count).toBeGreaterThan(0);
  expect(fontStatus.loaded).toBe(true);
  await page.screenshot({ path: 'artifacts/mustache2-menu.png', animations: 'disabled' });
  await page.locator('#start').click();
  await expect(page.locator('#overlay')).toHaveClass(/hidden/);
  await expect(page.locator('#world')).toBeVisible();
  await expect(page.locator('#roster .roster-person')).toHaveCount(3);
  await expect(page.locator('#timerFill')).toBeVisible();
  for (const selector of ['.side-panel', '.room-tag']) {
    const box = await page.locator(selector).boundingBox();
    expect(box).toBeTruthy();
    const topElement = await page.evaluate(({x,y}) => document.elementFromPoint(x,y)?.id, {
      x: box.x + box.width / 2, y: box.y + box.height / 2
    });
    expect(topElement).toBe('world');
  }
  await page.mouse.move(640, 420);
  await page.mouse.click(640, 420);
  await expect(page.locator('#accuracy')).not.toContainText('—');
  await page.keyboard.press('p');
  await expect(page.locator('#overlayTitle')).toContainText('استراحت');
  await page.locator('#start').click();
  await expect(page.locator('#overlay')).toHaveClass(/hidden/);
  await page.waitForTimeout(1000);
  const count = await page.locator('#caught').textContent();
  expect(count).toContain('۳');
  await page.screenshot({ path: 'artifacts/mustache2-game.png', animations: 'disabled' });
  expect(errors).toEqual([]);
});

test('mobile game controls and localized UI stay usable', async ({ browser }) => {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('/');
  await expect(page.locator('#overlayTitle')).toBeVisible();
  await page.locator('#start').click();
  await expect(page.locator('#touch')).toBeVisible();
  await expect(page.locator('.score-metric')).toBeVisible();
  await expect(page.locator('#score')).toHaveText('۰');
  const mission = await page.locator('.side-panel').boundingBox();
  const hint = await page.locator('#hint').boundingBox();
  expect(mission).toBeTruthy(); expect(hint).toBeTruthy();
  expect(mission.y + mission.height).toBeLessThan(hint.y);
  await page.locator('#inspect').click();
  await page.locator('#fire').click();
  await expect(page.locator('#accuracy')).not.toContainText('—');
  await page.screenshot({ path: 'artifacts/mustache2-mobile.png', animations: 'disabled' });
  expect(errors).toEqual([]);
  await context.close();
});
