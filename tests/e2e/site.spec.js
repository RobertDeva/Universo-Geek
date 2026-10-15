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
  await search.fill('servicios');
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
  await page.evaluate(() => localStorage.setItem('ug_theme', 'light'));
  await page.reload();
  const button = page.locator('[data-theme-toggle]');
  await expect(button).toBeVisible();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await button.click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await expect(button).toHaveAttribute('aria-pressed', 'false');
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
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

test('el marketplace busca sin tildes, filtra categorías y ordena por precio', async ({ page }) => {
  await page.route('**/rest/v1/marketplace_services?**', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: '1', user_id: 'seller-a', title: 'Ilustración de personaje anime', description: 'Avatar original', category: 'Ilustración', price_amount: 25, currency: 'USD', created_at: '2026-10-13T10:00:00Z' },
        { id: '2', user_id: 'seller-b', title: 'Edición de vídeo gaming', description: 'Clips para streaming', category: 'Edición', price_amount: 10, currency: 'USD', created_at: '2026-10-14T10:00:00Z' },
        { id: '3', user_id: 'seller-c', title: 'Diseño de banner', description: 'Banner para canal', category: 'Diseño', price_amount: 40, currency: 'USD', created_at: '2026-10-12T10:00:00Z' }
      ])
    });
  });
  await page.goto('/services.html');
  const cards = page.locator('.service-card');
  await expect(cards).toHaveCount(3);
  await page.locator('#service-search').fill('ilustracion');
  await expect(cards).toHaveCount(3);
  await expect(cards.filter({ hasText: 'Ilustración de personaje anime' })).toBeVisible();
  await expect(page.locator('#service-results-count')).toContainText('1 de 3');
  await page.locator('#service-search').clear();
  await page.locator('#service-category-filter').selectOption('Edición');
  await expect(page.locator('#service-results-count')).toContainText('1 de 3');
  await expect(cards.filter({ hasText: 'Edición de vídeo gaming' })).toBeVisible();
  await page.locator('#service-filters-reset').click();
  await page.locator('#service-sort').selectOption('price-asc');
  await expect(cards.first()).toContainText('Edición de vídeo gaming');
  await page.locator('#service-search').fill('no-existe');
  await expect(page.locator('#service-no-results')).toBeVisible();
  await page.locator('#service-filters-reset').click();
  await expect(page.locator('#service-results-count')).toContainText('3 servicios disponibles');
});
