# Cloudflare Pages — preparación segura de la demo

## Decisión de alojamiento

Para la demo de Universo Geek recomendamos Cloudflare Pages Free, separado de la plataforma de producción. El código actual es HTML, CSS y JavaScript nativo y no necesita npm ni un proceso de compilación complejo.

GitHub Pages es útil para prototipos estáticos, pero sus términos oficiales indican que no está destinado a alojar un negocio en línea, comercio electrónico o SaaS y que no debe usarse para transacciones sensibles como contraseñas. Como la demo incluye registro e inicio de sesión y recopila feedback, Cloudflare Pages es la opción más adecuada para esta validación.

## Qué hace el build

El script `bash scripts/build-demo.sh` crea `dist/` con una lista explícita de páginas públicas y los assets CSS/JS necesarios. No publica el repositorio entero, documentación interna, migraciones, pruebas ni archivos administrativos.

El script comprueba que:
- estén presentes todas las páginas públicas requeridas;
- la configuración de frontend apunte al proyecto Supabase de pruebas `tvjglznjntegujfczljp.supabase.co`;
- el artefacto no contenga patrones conocidos de claves/secretos de servidor.

La clave publishable de Supabase puede estar en el navegador. La seguridad de datos depende de RLS y del backend; nunca incluir una `service_role` ni una clave secreta.

## Configuración de Cloudflare Pages

1. En Cloudflare Dashboard, abre **Workers & Pages** y crea un proyecto Pages conectado a GitHub.
2. Selecciona el repositorio `RobertDeva/Universo-Geek`.
3. Establece como rama de producción `demo/public-validation-2026-10-18` después de integrar esta preparación mediante PR.
4. Configura el comando de compilación como `bash scripts/build-demo.sh`.
5. Configura el directorio de salida como `dist`.
6. Desactiva las vistas previas de ramas que no quieras exponer inicialmente. No configures `main` como rama de producción de este proyecto.
7. Cuando Cloudflare proporcione la URL `*.pages.dev`, añade ese origen exacto a Supabase de pruebas en **Authentication → URL Configuration → Site URL / Redirect URLs**.
8. Ejecuta el build y revisa el contenido publicado antes de compartir la URL.

No se requiere cambiar el DNS del dominio principal para usar la URL `pages.dev`. No conectes el dominio principal ni cambies la configuración de producción durante esta fase.

## Pruebas obligatorias antes de difundir

- Registro con un correo que controles y recepción del mensaje de confirmación.
- Inicio y cierre de sesión, recuperación de contraseña y redirecciones.
- Verificación de que un usuario no puede consultar ni modificar datos de otra cuenta.
- Listado de servicios, envío de solicitud y moderación.
- Feedback/asistente: confirmar que la Edge Function correspondiente está desplegada en el proyecto de pruebas; si no, debe mostrarse un error claro sin afirmar que el feedback fue guardado.
- Revisión de privacidad, cookies, términos y contacto.
- Comprobación desde móvil y escritorio.

## Límites de alcance

La demo no debe procesar pagos, crear membresías pagadas ni activar beneficios. No se cambia `main`, no se ejecutan migraciones en proyectos alojados y no se publica automáticamente desde esta guía. La conexión de Cloudflare, el ajuste de Supabase Auth y las pruebas reales requieren acceso autorizado al dashboard y comprobación manual.
