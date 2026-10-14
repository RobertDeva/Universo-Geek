# Preparar Cloudflare Pages (sin publicar)

Esta guía no realiza el despliegue. No conectar Git a Cloudflare ni pulsar Deploy hasta que el propietario lo autorice expresamente.

## Cuando se autorice

1. Entra en Cloudflare y abre Workers & Pages.
2. Crea un proyecto Pages y conecta el repositorio RobertDeva/Universo-Geek desde GitHub.
3. Selecciona la rama audit/rebuild-2026-10-14 para pruebas, no main hasta revisar y aprobar los cambios.
4. No indiques comando de build. El sitio usa archivos estáticos y no necesita npm.
5. Directorio de publicación: raíz del repositorio (/).
6. Revisa la vista previa antes de cualquier publicación final.

## Antes de probar autenticación

- En Supabase Auth, agrega la URL de vista previa exacta a las URL de redirección permitidas.
- Configura correo SMTP y revisa recuperación de contraseña.
- Habilita protección contra contraseñas filtradas.
- No coloques secretos de backend en variables de entorno de compilación del frontend. Las claves del navegador son públicas por diseño.
- Verifica desde dispositivos y redes objetivo; la disponibilidad desde Cuba puede variar según el proveedor y la red.

## Antes de publicación pública

- Sustituir todos los correos .example por un contacto real y autorizado.
- Completar el nombre legal/operador y revisar las políticas de privacidad y cookies.
- Conectar y probar las funciones de datos del marketplace y moderación.
- Validar pagos con QvaPay en un entorno de prueba; no habilitar el checkout mientras falte verificación de transacciones.
- Retirar unsafe-inline de CSP al mover los scripts inline a archivos locales.
- Revisar cabeceras de seguridad, accesibilidad, enlaces rotos, móvil y políticas RLS.
- Obtener autorización expresa para publicar.
