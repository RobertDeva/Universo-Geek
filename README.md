# Universo Geek — demo pública de validación

Esta rama, `demo/public-validation-2026-10-18`, contiene una demo gratuita aislada para comprobar interés, usabilidad y flujos básicos sin detener el desarrollo de la plataforma.

## Estado y alcance

- Demo estática para GitHub Pages, sin herramientas de compilación ni dependencias de CDN.
- Usa exclusivamente el proyecto Supabase de pruebas.
- Incluye portada, servicios, membresías informativas, registro/inicio de sesión, panel personal y páginas legales.
- Los cobros y la activación de membresías pagadas están desactivados.
- El panel de administración y los archivos internos no forman parte del artefacto público.
- No se considera lista para captar usuarios reales hasta probar registro, correo de confirmación, recuperación, RLS y feedback.

## Archivos importantes

- `index.html`: portada de la demo y aviso explícito de que los pagos están desactivados.
- `assets/js/config.js`: URL y clave publishable del proyecto Supabase de pruebas.
- `login.html`: registro, inicio de sesión y recuperación.
- `services.html`: marketplace en modo de solicitudes sin cobro.
- `dashboard.html`: sesión y pedidos de servicios.
- `privacy.html`, `cookies.html`, `terms.html`: documentos informativos que deben revisarse antes de la difusión.
- `DEMO-LAUNCH.md`: comprobaciones y pasos para activar GitHub Pages.

## Publicación

El workflow `.github/workflows/deploy-demo-pages.yml` construye un artefacto estático limitado a los archivos públicos de la demo. Configura **Settings → Pages → Build and deployment → GitHub Actions** y comprueba que el workflow termine correctamente.

Consulta [DEMO-LAUNCH.md](DEMO-LAUNCH.md) antes de anunciar el enlace. No publicar `main` como demo ni copiar su configuración de producción a esta rama.
