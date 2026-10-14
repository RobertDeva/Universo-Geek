# Informe de cambios en Supabase — 14 de octubre de 2026

Proyecto: `khadcbgzziuwaxwptftw`
Estado: cambios de base de datos aplicados y comprobados. Sitio no publicado. No se ha creado ni procesado ningún pago.

## Cambios aplicados

1. Se revocaron permisos de `TRUNCATE`, `REFERENCES` y `TRIGGER` a `anon` y `authenticated` en las tablas de `public`. Verificación posterior: ambos roles ya no pueden truncar ni activar triggers directamente.
2. Se añadieron índices para 10 claves foráneas señaladas por el asesor de rendimiento.
3. Se corrigió la política de reseñas completadas: ahora verifica que el `service_id` de la reseña coincida con el del pedido completado, que el usuario sea el comprador y que el pedido esté completado.
4. Se retiró el acceso anónimo a `profiles` y se limitó la actualización de perfiles autenticados a `display_name` y `avatar_url`. La actualización de `role` desde el navegador está bloqueada.
5. Los pedidos de membresías y compras digitales ya no se pueden insertar directamente desde el navegador. Deben ser creados por un backend de confianza que calcule el precio y los datos del proveedor.
6. Las compras digitales solo permiten actualizar `tx_hash` por el cliente; el cliente no puede cambiar estado ni precio.
7. Los pedidos del marketplace solo permiten actualizar el estado desde el navegador; no se pueden cambiar el comprador, vendedor, servicio, precio, moneda ni descripción después de crearlos.
8. El registro de auditoría administrativa quedó de solo lectura para el navegador, sujeto a su política RLS de administradores.
9. Se optimizaron las políticas RLS que llamaban repetidamente a funciones de autenticación.
10. La política de creación de pedidos del marketplace ahora verifica que el importe y la moneda coincidan con el servicio aprobado.

## Verificación posterior

Se consultaron las políticas y privilegios efectivos. Resultados confirmados:

- `anon` no tiene acceso de lectura a `profiles`.
- `authenticated` no puede actualizar `profiles.role`; sí puede actualizar `display_name` y `avatar_url`.
- `authenticated` no puede insertar pedidos de membresía ni compras digitales.
- `authenticated` puede modificar `tx_hash` de una compra digital pendiente, pero no su estado.
- `authenticated` solo tiene privilegio de columna para actualizar el estado de pedidos de servicio.
- `anon` y `authenticated` no tienen privilegio de `TRUNCATE` ni de `TRIGGER` en las tablas públicas.
- La política de pedido de servicio compara `agreed_amount` y `currency` con la ficha aprobada.

## Hallazgos pendientes

### Acción manual de Auth
El asesor de seguridad todavía reporta `auth_leaked_password_protection`: la protección contra contraseñas filtradas está desactivada. No encontré una herramienta autorizada para cambiar ese ajuste directamente desde esta sesión. Actívalo en Supabase Dashboard, en Authentication / Security and Protection, y vuelve a ejecutar el asesor.

Documentación oficial: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

### Rendimiento
El asesor ya no reporta claves foráneas sin índice ni políticas con reevaluación de funciones Auth. Permanecen advertencias sobre políticas permisivas superpuestas y 35 índices no usados. En un proyecto recién creado, la estadística de uso puede ser insuficiente para decidir si borrar índices; no se eliminaron índices existentes.

### QvaPay
No hay Edge Functions desplegadas y el checkout sigue desactivado. Como la cuenta comercial está pendiente, no se han inventado credenciales, no se han creado facturas y no se ha activado ninguna membresía de pago. Cuando QvaPay responda, se verificará el contrato real del webhook y se guardarán las credenciales únicamente como secretos de Edge Functions.

## Migraciones

Las cuatro migraciones aplicadas en esta sesión están versionadas en `supabase/migrations` con sus versiones reales de Supabase:
- `20261014081504_tighten_public_grants_review_policy_and_fk_indexes.sql`
- `20261014081711_tighten_audit_profile_grants_and_optimize_rls_predicates.sql`
- `20261014081752_secure_client_writes_and_optimize_rls.sql`
- `20261014081901_validate_marketplace_order_price_against_service.sql`

Las migraciones históricas están sincronizadas en `supabase/migrations/`, incluyendo un marcador saneado para `bootstrap_initial_site_admin` que no almacena el correo del propietario. Para configurar el administrador en un entorno nuevo, sigue `docs/ADMIN-BOOTSTRAP.md`.

La rama `main` no se modificó. Los cambios están en `audit/rebuild-2026-10-14`.
