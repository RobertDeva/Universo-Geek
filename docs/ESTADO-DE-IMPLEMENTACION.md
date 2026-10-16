# Estado de implementación — 16 de octubre de 2026

La rama `main` contiene la base integrada de HTML, CSS y JavaScript nativo. No requiere npm, bundler ni CDN. Los PR #10, #14, #15, #16, #17, #18, #19, #20 y #21 están integrados; el sitio **no se ha desplegado públicamente**. La rama `audit/rebuild-2026-10-14` está divergente y no debe fusionarse en bloque.

## Incluido en esta fase
- Portada y navegación móvil.
- Registro, inicio de sesión y recuperación de contraseña mediante Supabase Auth.
- Renovación automática de sesión cuando el access token expira y existe un refresh token.
- Panel personal mínimo con comprobación de sesión.
- Marketplace conectado a Supabase: lista servicios aprobados, permite enviar servicios a moderación y crea solicitudes para servicios aprobados.
- Panel personal con lista de pedidos del usuario y transiciones de estado de comprador/vendedor validadas por RLS y trigger.
- La política RLS de la base de datos comprueba que el precio y la moneda de una solicitud coincidan con el anuncio aprobado.
- Borradores de privacidad y cookies.
- Centro de moderación funcional para servicios y anuncios de afiliados, con verificación de rol y RPCs seguras que registran las decisiones en auditoría.
- Asistente local de FAQ en todas las páginas, con formulario de feedback, tabla `site_feedback` protegida por RLS y bandeja de seguimiento para administradores.
- Gestión de roles y transacciones financieras continúa restringida a administradores/backend; la página no permite activar pagos.
- Cabeceras iniciales de seguridad, guía de Cloudflare Pages e informe de seguridad de Supabase.

## Seguridad aplicada en Supabase
- Revocados privilegios de TRUNCATE, REFERENCES y TRIGGER a los roles de navegador.
- Añadidos índices para claves foráneas detectadas por el asesor.
- Corregida la política de reseñas para validar comprador, pedido completado y servicio correspondiente.
- Restringidas las columnas de perfil que el usuario puede actualizar.
- Restringidos los cambios de pedidos de servicio a su estado, con validación de transiciones.
- El cliente ya no puede insertar pedidos de membresías o compras digitales. Esas órdenes deberán crearse desde un backend que calcule precios y referencias.
- Los registros de auditoría administrativa no se pueden escribir directamente desde el navegador.
- El rol moderator ya no puede promover cuentas a admin; las funciones de moderación se limitan a servicios/anuncios y contenido comunitario.
- Las migraciones están versionadas en `supabase/migrations/`. El bootstrap histórico del administrador se conserva como marcador sin correo personal; consulta `docs/ADMIN-BOOTSTRAP.md` para preparar otro entorno.
- La reproducción limpia de las migraciones en Supabase local pasó en CI en PR #14. Esa prueba no modifica los proyectos Supabase alojados.

## Limitaciones deliberadas
- La moderación de servicios y anuncios ya está conectada; el panel de administración general para usuarios, roles y transacciones todavía no está completo.
- El checkout está desactivado. No se crean facturas, no se aceptan pagos y no se activan membresías pagadas.
- Las funciones Edge de QvaPay no se han desplegado; falta la cuenta comercial y confirmar el formato real del webhook.
- Formularios de contacto, newsletter, favoritos, compras digitales y contenido editorial no están conectados completamente. El feedback del asistente sí está conectado.
- Los correos con dominio `.example` son marcadores de posición y deben reemplazarse.
- La política de privacidad/cookies es un borrador y requiere datos del operador y revisión legal.

## Asistente y feedback
- El bot responde con reglas estáticas basadas en las páginas y flujos comprobados del sitio; no usa IA externa. Las preguntas no reconocidas o ambiguas reciben una respuesta de incertidumbre, no una invención.
- Los pagos/membresías se describen como desactivados hasta que se apruebe y pruebe la cuenta comercial de QvaPay.
- El envío de feedback pasa por la Edge Function `submit-site-feedback`: valida el JSON y los campos, verifica sesiones presentadas, limita el tamaño de solicitud, aplica máximo cinco envíos por hash de IP por hora y no guarda la IP sin procesar.
- En el proyecto de pruebas, la tabla de límites tiene una política explícita de denegación y privilegios de cliente revocados. En el proyecto principal, ese cambio aún no se ha aplicado; el Security Advisor sigue mostrando el hallazgo correspondiente. Los navegadores no pueden insertar directamente en `site_feedback`; la función de servidor llama al RPC con permisos restringidos.
- La bandeja de administradores incluye estadísticas agregadas: total, pendientes, últimos 30 días y valoración media.
- La función Edge `submit-site-feedback` está activa en el proyecto Supabase principal; el proyecto de pruebas `tvjglznjntegujfczljp` no tiene Edge Functions desplegadas. El feedback desde una vista previa que use ese proyecto de pruebas no está verificado y requiere desplegar la función allí antes de probarlo.
- La sintaxis del JavaScript del navegador y los scripts inline de administración se han comprobado. Aún falta una prueba de extremo a extremo desde un navegador real con usuario anónimo y usuario autenticado.

## Configuración de Supabase pendiente
1. Añadir las URL de redirección exactas para el origen de prueba y el origen de publicación autorizado. No desplegar la rama principal en una vista previa mientras `assets/js/config.js` apunte al proyecto Supabase principal.
2. Configurar correo SMTP y recuperación de cuenta.
3. Revisar la protección contra contraseñas filtradas en Authentication → Security and Protection. La documentación de Supabase indica que está disponible en Pro y superiores; si el proyecto está en Free, no actualizar el plan sin revisar el coste.
4. Probar RLS con usuarios separados de tipo user, moderator y admin.

## Pruebas y verificación
- Verificados en Supabase los privilegios efectivos de roles y columnas tras las migraciones.
- Verificada la política de creación de pedidos del marketplace contra el importe y moneda del anuncio.
- El Security Advisor del proyecto Supabase principal sigue mostrando hallazgos: `admin_site_feedback_stats()` expuesta como `SECURITY DEFINER`, la tabla `site_feedback_rate_limits` con RLS sin política explícita y la protección contra contraseñas filtradas desactivada. Las migraciones correctivas y el endurecimiento de permisos de órdenes están versionados en `main`, pero **no se han aplicado al proyecto principal**; por tanto, estos hallazgos no se consideran resueltos en producción. El índice de `site_feedback.user_id` también está versionado, pero el aviso de rendimiento seguirá hasta aplicar esa migración.
- El asesor de rendimiento ya no reporta claves foráneas sin índice ni evaluaciones Auth repetidas; quedan avisos de políticas permisivas superpuestas e índices sin uso que no deben eliminarse sin métricas de tráfico.
- La validación estática de autenticación pasó en CI en PR #15; la validación estática del sitio pasó en PR #18/#19; la reproducción limpia de migraciones pasó en PR #14/#17/#20/#21.
- No se han completado pruebas de navegador ni transacciones reales. Los registros recientes de Auth muestran una solicitud de registro desde GitHub Pages, pero no una solicitud desde la vista previa de Cloudflare; todavía hace falta probar el registro desde el origen exacto que se va a utilizar.

## Próximas tareas
1. Revisar y, con autorización expresa, aplicar las migraciones de seguridad al proyecto Supabase principal; volver a ejecutar Security Advisor.
2. Habilitar protección contra contraseñas filtradas en el Dashboard.
3. Probar registro, inicio, confirmación de correo, recuperación y renovación de sesión desde un origen de staging autorizado.
4. Completar las herramientas administrativas generales de usuarios/roles; la moderación de anuncios y el flujo básico de pedidos sí están conectados.
5. Revisar la cadena CSP y mover los scripts inline a archivos locales para poder retirar `unsafe-inline`.
6. Cuando QvaPay apruebe la cuenta comercial, implementar y probar las funciones de facturación y verificación sin exponer secretos.
7. Completar datos legales/contacto, reemplazar correos `.example`, revisar privacidad/cookies y publicar solo con autorización expresa.
