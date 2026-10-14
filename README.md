# Universo Geek

Proyecto web para comunidad gamer, anime, manga y manhwa, con enfoque en Latinoamérica y Estados Unidos.

## Estado actual del repositorio

Este repositorio todavía no contiene el sitio web completo. La rama `main` conserva el commit inicial. La rama de trabajo `audit/rebuild-2026-10-14` contiene una auditoría técnica con los bloqueadores y las condiciones para preparar una reconstrucción segura.

Lee primero: [Auditoría técnica del 14 de octubre de 2026](AUDITORIA-TECNICA-2026-10-14.md).

## Arquitectura prevista

- Frontend estático con HTML, CSS y JavaScript nativo.
- Sin npm, bundlers, frameworks ni CDNs externos.
- Supabase Auth y PostgreSQL con RLS para perfiles, contenido, servicios y membresías.
- Panel de usuario y panel de moderación/administración adaptables a móviles.
- Membresías y marketplace; pagos mediante backend de confianza, no desde el navegador.
- Preparación futura para Cloudflare Pages, con publicación desactivada hasta autorización explícita.

## Seguridad esencial

- La clave publicable de Supabase puede utilizarse en el navegador; nunca incluir una clave `service_role`, claves secretas ni secretos de QvaPay en archivos públicos.
- No activar membresías pagadas por una redirección del navegador. Solo un backend debe validar la transacción, el importe, la referencia y el estado del proveedor.
- Mantener RLS habilitado y probar los permisos con cuentas de distintos roles.
- No ejecutar migraciones sin compararlas primero con el esquema actual y realizar una copia de seguridad.

## Próximo trabajo

1. Incorporar y revisar el paquete de frontend y backend en una rama independiente.
2. Comparar sus SQL con el esquema real de Supabase para evitar migraciones duplicadas o destructivas.
3. Revisar las funciones de pago QvaPay y probarlas con credenciales configuradas como secretos.
4. Completar las pruebas funcionales y de seguridad.
5. Mantener el sitio sin publicar hasta recibir autorización explícita.
