# Migraciones de Supabase

Los archivos SQL de esta carpeta describen los cambios de esquema y seguridad aplicados al proyecto.

## Regla principal: no reescribir historia

- Una migración ya aplicada es inmutable. No edites ni renombres ese archivo para cambiar el comportamiento.
- Para cualquier cambio nuevo, crea un archivo con una versión nueva y un nombre breve que explique el objetivo.
- Conserva exactamente el SQL aplicado en Supabase y versionado en GitHub.
- Revisa RLS, grants, funciones, triggers, restricciones e índices como parte del mismo cambio cuando corresponda.
- Antes de ejecutar SQL en producción, revisa el plan, haz copia de seguridad cuando sea posible y prueba en un proyecto de desarrollo.
- Nunca incluyas contraseñas, claves privadas, tokens ni datos personales en una migración.

## Flujo recomendado

1. Define el cambio y sus condiciones de seguridad.
2. Crea un nuevo archivo SQL con versión única y nombre descriptivo.
3. Revisa el SQL con otra persona o con una revisión independiente.
4. Aplica el cambio en el entorno de desarrollo.
5. Prueba el comportamiento con cuentas de user, moderator y admin.
6. Aplica al proyecto activo solo después de revisar los resultados.
7. Comprueba el historial de migraciones y documenta cualquier tarea pendiente.

No ejecutes todos los archivos de esta carpeta contra la base de datos activa: Supabase mantiene el historial de las migraciones que ya se aplicaron.
