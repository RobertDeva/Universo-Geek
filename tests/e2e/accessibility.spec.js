const { test, expect } = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;

test('accesibilidad: portada sin violaciones graves o críticas', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();
  const serious = results.violations.filter(v => v.impact === 'serious' || v.impact === 'critical');
  expect(serious, JSON.stringify(serious.map(v => ({ id: v.id, impact: v.impact, help: v.help, nodes: v.nodes.length })), null, 2)).toEqual([]);
});

test('accesibilidad: página de servicios sin violaciones graves o críticas', async ({ page }) => {
  await page.goto('/services.html');
  const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();
  const serious = results.violations.filter(v => v.impact === 'serious' || v.impact === 'critical');
  expect(serious, JSON.stringify(serious.map(v => ({ id: v.id, impact: v.impact, help: v.help, nodes: v.nodes.length })), null, 2)).toEqual([]);
});
