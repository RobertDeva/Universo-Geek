const { test, expect } = require('@playwright/test');

test('la portada carga y muestra contenido esencial', async ({ page }) => {
  const response = await page.goto('/');
  expect(response && response.ok()).toBeTruthy();
  await expect(page).toHaveTitle(/Universo Geek/i);
  await expect(page.getByRole('heading', { name: /Tu universo/i })).toBeVisible();
  await expect(page.locator('[data-section-search]')).toBeVisible();
  await expect(page.locator('[data-search-card]')).toHaveCount(4);
});

test('la búsqueda filtra secciones y no distingue tildes', async ({ page }) => {
  await page.goto('/');
  const search = page.locator('[data-section-search]');
  await search.fill('ilustracion');
  await expect(page.locator('#section-services')).toBeVisible();
  await expect(page.locator('#section-gaming')).toBeHidden();
  await expect(page.locator('[data-search-status]')).toContainText(/1 sección encontrada/i);
  await search.fill('termino-que-no-existe');
  await expect(page.locator('[data-search-status]')).toContainText(/No encontramos/i);
  await search.clear();
  await expect(page.locator('[data-search-card]')).toHaveCount(4);
});

test('el selector de tema alterna y conserva la preferencia', async ({ page }) => {
  await page.goto('/');
  const button = page.locator('[data-theme-toggle]');
  await expect(button).toBeVisible();
  await button.click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await expect(button).toHaveAttribute('aria-pressed', 'true');
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});

test('la navegación móvil abre, expone su estado y cierra con Escape', async ({ page, isMobile }) => {
  test.skip(!isMobile, 'Prueba específica de viewport móvil');
  await page.goto('/');
  const toggle = page.locator('.menu-toggle');
  const nav = page.locator('.nav');
  await expect(toggle).toBeVisible();
  await toggle.click();
  await expect(toggle).toHaveAttribute('aria-expanded', 'true');
  await expect(nav).toHaveClass(/open/);
  await page.keyboard.press('Escape');
  await expect(toggle).toHaveAttribute('aria-expanded', 'false');
  await expect(nav).not.toHaveClass(/open/);
});

test('todas las páginas HTML principales responden correctamente', async ({ request }) => {
  const pages = [
    'index.html', 'login.html', 'services.html', 'membership.html',
    'privacy.html', 'cookies.html', 'terms.html'
  ];
  for (const path of pages) {
    const response = await request.get('/' + path);
    expect(response.status(), path + ' debe responder 200').toBe(200);
    expect(response.headers()['content-type'] || '').toContain('text/html');
  }
});

test('no aparecen errores JavaScript no controlados en la portada', async ({ page }) => {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/');
  await expect(page.getByRole('heading', { name: /Tu universo/i })).toBeVisible();
  expect(errors).toEqual([]);
});
