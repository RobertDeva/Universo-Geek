# Migraciones de Supabase

Los archivos SQL de esta carpeta describen los cambios de esquema y seguridad aplicados al proyecto.

## Regla principal: no reescribir historia

- Una migración ya aplicada es inmutable. No edites ni renombres ese archivo para cambiar el comportamiento.
- Para cualquier cambio nuevo, crea un archivo con una versión nueva y un nombre breve que explique el objetivo.
- Conserva exactamente el SQL aplicado en Supabase y versionado en GitHub.
- Revisa RLS, grants, funciones, triggers, restricciones e índices como parte del mismo cambio cuando corresponda.
- Antes de ejecutar SQL en producción, revisa el plan, haz copia de seguridad cuando sea posible y prueba en un proyecto de desarrollo.
- Nunca incluyas contraseñas, claves privadas, tokens ni datos personales en una migración.

## Excepción de compatibilidad histórica — 16 de octubre de 2026

Durante la preparación del lanzamiento, la prueba de reconstrucción limpia detectó que varias migraciones heredadas dependían de funciones, tablas o columnas que existían en el esquema alojado, pero no en el esquema base versionado. Para que una instalación nueva pueda reproducir el esquema, se ajustaron estas migraciones históricas:

- `20261013190500_tighten_function_permissions.sql`
- `20261013223613_qvapay_memberships.sql`
- `20261014081504_tighten_public_grants_review_policy_and_fk_indexes.sql`
- `20261014081711_tighten_audit_profile_grants_and_optimize_rls_predicates.sql`
- `20261014081752_secure_client_writes_and_optimize_rls.sql`
- `20261014082608_separate_admin_and_moderator_permissions.sql`

**Esta es una excepción única, no una nueva práctica.** El proyecto Supabase principal ya registró estas versiones, por lo que no se deben volver a ejecutar manualmente ni tratar como migraciones nuevas. El SQL histórico de producción puede diferir del archivo actual de GitHub. Los cambios de seguridad destinados a una base alojada deben ir en nuevas migraciones con versiones nuevas, revisarse y aplicarse solo tras autorización expresa. Antes de usar `supabase db push`, compara el historial remoto con el local y confirma el plan; no uses `migration repair` para ocultar diferencias.

## Flujo recomendado

1. Define el cambio y sus condiciones de seguridad.
2. Crea un nuevo archivo SQL con versión única y nombre descriptivo.
3. Revisa el SQL con otra persona o con una revisión independiente.
4. Aplica el cambio en el entorno de desarrollo.
5. Prueba el comportamiento con cuentas de user, moderator y admin.
6. Aplica al proyecto activo solo después de revisar los resultados.
7. Comprueba el historial de migraciones y documenta cualquier tarea pendiente.

No ejecutes todos los archivos de esta carpeta contra la base de datos activa: Supabase mantiene el historial de las migraciones que ya se aplicaron.
