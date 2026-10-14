# Estado de implementación — 14 de octubre de 2026

Esta rama contiene una base estática reconstruida con HTML, CSS y JavaScript nativo. No requiere npm, bundler ni CDN. Se mantiene separada de `main` y **no está publicada**.

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

## Limitaciones deliberadas
- La moderación de servicios y anuncios ya está conectada; el panel de administración general para usuarios, roles y transacciones todavía no está completo.
- El checkout está desactivado. No se crean facturas, no se aceptan pagos y no se activan membresías pagadas.
- Las funciones Edge de QvaPay no se han desplegado; falta la cuenta comercial y confirmar el formato real del webhook.
- Formularios de contacto, newsletter, favoritos, compras digitales y contenido editorial no están conectados completamente.
- Los correos con dominio `.example` son marcadores de posición y deben reemplazarse.
- La política de privacidad/cookies es un borrador y requiere datos del operador y revisión legal.

## Configuración de Supabase pendiente
1. Agregar solo las URL de redirección necesarias para el entorno de prueba.
2. Configurar correo SMTP y recuperación de cuenta.
3. **Activar la protección contra contraseñas filtradas** en Authentication → Security and Protection. El asesor de seguridad todavía informa que está deshabilitada.
4. Probar RLS con usuarios separados de tipo user, moderator y admin.

## Pruebas y verificación
- Verificados en Supabase los privilegios efectivos de roles y columnas tras las migraciones.
- Verificada la política de creación de pedidos del marketplace contra el importe y moneda del anuncio.
- El asesor de seguridad solo mantiene el aviso de protección de contraseñas filtradas.
- El asesor de rendimiento ya no reporta claves foráneas sin índice ni evaluaciones Auth repetidas; quedan avisos de políticas permisivas superpuestas e índices sin uso que no deben eliminarse sin métricas de tráfico.
- No se han ejecutado pruebas de navegador ni transacciones reales. La autenticación debe probarse desde un origen autorizado en Supabase.

## Próximas tareas
1. Habilitar protección contra contraseñas filtradas en el Dashboard.
2. Probar registro, inicio, recuperación y renovación de sesión desde un entorno local/staging.
3. Completar las herramientas administrativas de usuarios/roles; moderación de anuncios y el flujo básico de pedidos ya están conectados.
4. Revisar la cadena CSP y mover los scripts inline a archivos locales para poder retirar `unsafe-inline`.
5. Cuando QvaPay apruebe la cuenta comercial, implementar y probar las funciones de facturación y verificación sin exponer secretos.
6. Completar datos legales/contacto y solo publicar con autorización expresa.
