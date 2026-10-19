# Auditoría de desarrollo y puertas de lanzamiento — 18 de octubre de 2026

## Alcance

Esta auditoría se realizó leyendo la rama `main`, la lista de ramas remotas y las comparaciones de GitHub. No se accedió a una sesión de navegador, al panel de Cloudflare ni se ejecutaron consultas contra las bases Supabase alojadas. Por tanto, no sustituye las pruebas manuales ni confirma el estado actual de los servicios externos.

## Resultado ejecutivo

**Estado: NO LISTO PARA PUBLICACIÓN.** No desplegar ni activar pagos reales como consecuencia de esta auditoría.

### Verificado en GitHub

- `main` es la base de trabajo y contiene la documentación de estado y la lista de preparación fechadas el 16 de octubre de 2026.
- La documentación indica que los PR #10, #14–#21 se integraron, incluidas correcciones de autenticación, permisos de cliente, marketplace y base de GeekPoints.
- La lista de preparación mantiene pendientes la aplicación de migraciones correctivas al Supabase principal, pruebas de Auth desde el origen exacto de staging, pruebas RLS por rol, validación de navegador, datos legales y autorización final.
- QvaPay y el checkout se mantienen desactivados en el estado documentado.
- La configuración pública de `main` (`assets/js/config.js`) apunta a `https://khadcbgzziuwaxwptftw.supabase.co`. No debe copiarse esta configuración a un entorno de prueba si se pretende aislarlo del proyecto principal.
- No hay solicitudes de extracción abiertas en el repositorio al momento de esta consulta.

## Ramas divergentes: no fusionar en bloque

Las comparaciones con `main` devolvieron:

| Rama | Resultado de comparación | Decisión |
|---|---|---|
| `audit/rebuild-2026-10-14` | La documentación del proyecto la identifica como divergente | No fusionar en bloque; rescatar cambios mediante revisión por archivo |
| `fix/auth-registration-main-2026-10-16` | 5 commits por delante y 9 por detrás; cambios en `login.html` y un workflow | No fusionar directamente; comparar el parche contra la implementación actual de `main` |
| `fix/supabase-migration-compatibility-main` | 9 commits por delante y 9 por detrás; toca migraciones de permisos y seguridad | Revisión SQL línea por línea antes de rescatar cualquier cambio |
| `fix/backend-only-payment-order-writes-2026-10-16` | 4 commits por delante y 2 por detrás; agrega una migración | Revisar dependencias, orden de migración y compatibilidad con el esquema actual |
| `docs/release-readiness-final-2026-10-16` | 2 commits por delante y 1 por detrás; solo cambios documentales según comparación | No hace falta fusionar toda la rama; rescatar únicamente diferencias documentales útiles |

Los conteos son los reportados por GitHub Compare para las referencias consultadas; no implican que todos los commits sean cambios exclusivos ni que los archivos sean seguros de integrar.

## Orden de ejecución recomendado

1. **Aislar y probar staging.** Confirmar la URL y clave pública del proyecto de pruebas; revisar las URL de redirección autorizadas en Supabase Auth. No usar datos reales para pruebas destructivas.
2. **Autenticación.** Probar registro, confirmación de correo, inicio y cierre de sesión, recuperación de contraseña y renovación de sesión desde la URL exacta de staging.
3. **Migraciones y RLS.** Revisar el SQL versionado, aplicar primero en un entorno de prueba desechable y obtener aprobación antes de aplicar cambios al proyecto principal. Volver a ejecutar Security Advisor y registrar evidencia.
4. **Pruebas funcionales.** Probar moderación, marketplace, pedidos, feedback y permisos con cuentas distintas de usuario, moderador y administrador.
5. **Revisión del cliente.** Comprobar errores JavaScript, enlaces, formularios, navegación móvil, accesibilidad y cabeceras CSP. No introducir dependencias de compilación o CDN innecesarias.
6. **Pagos.** Mantener desactivados checkout y membresías pagadas hasta disponer de creación de órdenes confiable, verificación servidor a servidor, idempotencia y pruebas del proveedor.
7. **Preparación de publicación.** Sustituir contactos de ejemplo, completar datos legales, revisar privacidad/cookies, comprobar el artefacto de despliegue y pedir autorización expresa antes de publicar.

## Puertas de seguridad

- Nunca exponer `service_role`, claves secretas, claves privadas ni secretos de webhook en archivos del navegador.
- No declarar una migración como aplicada solo porque el archivo exista en GitHub.
- No declarar una prueba de navegador aprobada si no se ejecutó y guardó evidencia.
- No cambiar `main` directamente durante la implementación.
- No fusionar ramas divergentes completas solo para reducir el número de ramas.
- No desplegar ni activar cobros reales sin autorización expresa.

## Registro de acciones

- Se creó el issue de seguimiento [#23 — Resolver bloqueos de seguridad, autenticación y pruebas antes del lanzamiento](https://github.com/RobertDeva/Universo-Geek/issues/23).
- Esta nota se incorpora en una rama independiente para revisión.
