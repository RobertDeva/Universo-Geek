# Auditoría de desarrollo y puertas de lanzamiento — 18 de octubre de 2026

## Alcance

Esta auditoría consultó las ramas y archivos de GitHub, comparaciones de commits y los informes de Security Advisor y Performance Advisor de los dos proyectos Supabase conectados. No se accedió a una sesión de navegador ni al panel de Cloudflare. No se aplicaron migraciones ni se ejecutaron escrituras en las bases alojadas. Por tanto, no sustituye las pruebas manuales ni confirma la configuración actual de los servicios externos.

## Resultado ejecutivo

**Estado: NO LISTO PARA PUBLICACIÓN.** No desplegar ni activar pagos reales como consecuencia de esta auditoría.

### Verificado en GitHub

- `main` es la base de trabajo y contiene la documentación de estado y la lista de preparación fechadas el 16 de octubre de 2026.
- La documentación indica que los PR #10, #14–#21 se integraron, incluidas correcciones de autenticación, permisos de cliente, marketplace y base de GeekPoints.
- La lista de preparación mantiene pendientes la aplicación de migraciones correctivas al Supabase principal, pruebas de Auth desde el origen exacto de staging, pruebas RLS por rol, validación de navegador, datos legales y autorización final.
- QvaPay y el checkout se mantienen desactivados en el estado documentado.
- La configuración pública de `main` (`assets/js/config.js`) apunta a `https://khadcbgzziuwaxwptftw.supabase.co`. No debe copiarse esta configuración a un entorno de prueba si se pretende aislarlo del proyecto principal.
- Al iniciar la auditoría no se encontraron PR abiertos; como resultado de este trabajo se abrió el PR #24, solo documental.

## Estado de Supabase — lectura de asesores en vivo

### Proyecto principal: `khadcbgzziuwaxwptftw`

El Security Advisor sigue reportando tres hallazgos:

1. **RLS habilitado sin política explícita** en `public.site_feedback_rate_limits`.
2. **Función privilegiada accesible desde el API público:** `public.admin_site_feedback_stats()` puede ejecutarse como `SECURITY DEFINER` por el rol `authenticated`.
3. **Protección contra contraseñas filtradas desactivada** en Supabase Auth.

El Performance Advisor informa un índice pendiente para la clave foránea `site_feedback.user_id`, 36 índices sin uso observado y 25 conjuntos de políticas permisivas superpuestas. Los índices sin uso no deben eliminarse sin métricas representativas; las políticas superpuestas requieren revisión para distinguir advertencias de rendimiento de problemas de autorización.

El proyecto principal tiene 24 migraciones registradas y la Edge Function `submit-site-feedback` activa (versión 2). El recuento de migraciones por sí solo no demuestra que los cambios de seguridad recientes estén aplicados.

### Proyecto de pruebas: `tvjglznjntegujfczljp`

El Security Advisor no devuelve los dos hallazgos de base de datos anteriores; sí indica que la protección contra contraseñas filtradas está desactivada.

El Performance Advisor informa cuatro claves foráneas sin índice, 20 índices sin uso observado y 21 conjuntos de políticas permisivas superpuestas. El proyecto tiene 28 migraciones registradas, incluidas migraciones de prueba que parecen cubrir las dos correcciones de seguridad, pero hay que verificar el esquema y los permisos efectivos antes de considerarlas aprobadas.

**Bloqueo de integración:** el proyecto de pruebas no tiene Edge Functions desplegadas. La función `submit-site-feedback` sí está activa en el proyecto principal. No probar el formulario de feedback desde staging hasta desplegar y validar la función en el proyecto de pruebas, o configurar explícitamente el entorno aislado para una alternativa segura.

Referencias de remediación:
- [RLS sin política](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)
- [Función SECURITY DEFINER accesible por usuarios autenticados](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)
- [Protección de contraseñas filtradas](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
- [Claves foráneas sin índice](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys)

## Ramas divergentes: no fusionar en bloque

Las comparaciones con `main` devolvieron:

| Rama | Resultado de comparación | Decisión |
|---|---|---|
| `audit/rebuild-2026-10-14` | La documentación del proyecto la identifica como divergente | No fusionar en bloque; rescatar cambios mediante revisión por archivo |
| `fix/auth-registration-main-2026-10-16` | 5 commits por delante y 9 por detrás; cambios en `login.html` y un workflow | No fusionar directamente; comparar el parche contra la implementación actual de `main` |
| `fix/supabase-migration-compatibility-main` | 9 commits por delante y 9 por detrás; toca migraciones de permisos y seguridad | Revisión SQL línea por línea antes de rescatar cualquier cambio |
| `fix/backend-only-payment-order-writes-2026-10-16` | 4 commits por delante y 2 por detrás; agrega una migración | Revisar dependencias, orden de migración y compatibilidad con el esquema actual |
| `docs/release-readiness-final-2026-10-16` | 2 commits por delante y 1 por detrás; solo cambios documentales según comparación | No hace falta fusionar toda la rama; rescatar únicamente diferencias documentales útiles |

La rama de autenticación contiene el mismo `login.html` que `main` en la comparación actual; no justifica fusionar sus commits divergentes solo para obtener ese archivo. El workflow estático adicional puede rescatarse por separado si se verifica su ejecución en una PR real.

Los conteos son los reportados por GitHub Compare para las referencias consultadas; no implican que todos los commits sean cambios exclusivos ni que los archivos sean seguros de integrar.

## Orden de ejecución recomendado

1. **Aislar y probar staging.** Confirmar la URL y clave pública del proyecto de pruebas; revisar las URL de redirección autorizadas en Supabase Auth. No usar datos reales para pruebas destructivas.
2. **Autenticación.** Probar registro, confirmación de correo, inicio y cierre de sesión, recuperación de contraseña y renovación de sesión desde la URL exacta de staging.
3. **Migraciones y RLS.** Revisar el SQL versionado, aplicar primero en un entorno de prueba desechable y obtener aprobación antes de aplicar cambios al proyecto principal. Volver a ejecutar Security Advisor y registrar evidencia.
4. **Funciones Edge.** Desplegar y probar las funciones necesarias en staging, comenzando por `submit-site-feedback`, sin copiar secretos de producción a la vista previa.
5. **Pruebas funcionales.** Probar moderación, marketplace, pedidos, feedback y permisos con cuentas distintas de usuario, moderador y administrador.
6. **Revisión del cliente.** Comprobar errores JavaScript, enlaces, formularios, navegación móvil, accesibilidad y cabeceras CSP. No introducir dependencias de compilación o CDN innecesarias.
7. **Pagos.** Mantener desactivados checkout y membresías pagadas hasta disponer de creación de órdenes confiable, verificación servidor a servidor, idempotencia y pruebas del proveedor.
8. **Preparación de publicación.** Sustituir contactos de ejemplo, completar datos legales, revisar privacidad/cookies, comprobar el artefacto de despliegue y pedir autorización expresa antes de publicar.

## Puertas de seguridad

- Nunca exponer `service_role`, claves secretas, claves privadas ni secretos de webhook en archivos del navegador.
- No declarar una migración como aplicada solo porque el archivo exista en GitHub.
- No declarar una prueba de navegador aprobada si no se ejecutó y guardó evidencia.
- No cambiar `main` directamente durante la implementación.
- No fusionar ramas divergentes completas solo para reducir el número de ramas.
- No desplegar ni activar cobros reales sin autorización expresa.

## Registro de acciones

- Se creó el issue de seguimiento [#23 — Resolver bloqueos de seguridad, autenticación y pruebas antes del lanzamiento](https://github.com/RobertDeva/Universo-Geek/issues/23).
- Se abrió el [PR #24 — Auditoría de desarrollo y bloqueos de lanzamiento](https://github.com/RobertDeva/Universo-Geek/pull/24) en una rama independiente. Es un cambio documental, no modifica `main`.
