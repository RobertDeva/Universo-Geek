# Universo Geek — lanzamiento de la demo

Esta rama está separada de `main` y del desarrollo ordinario: `demo/public-validation-2026-10-18`.

## Alcance de la demo

- Portada, catálogo de servicios, información de membresías y páginas legales.
- Registro/inicio de sesión y panel de usuario conectados al proyecto Supabase **de pruebas**.
- Solicitudes de servicios sujetas a las políticas de la base de datos y moderación.
- Asistente de ayuda/feedback cuando la Edge Function de pruebas está disponible.
- Los cobros, el checkout de membresías y la activación de pagos permanecen desactivados.
- El panel de administración no se publica como parte del artefacto de Pages.

## Protección del entorno

La configuración pública de esta rama debe apuntar exclusivamente a `tvjglznjntegujfczljp.supabase.co`. No copies aquí la configuración de `main` ni uses una clave `service_role`. La clave publishable puede estar en el navegador; la seguridad real depende de RLS y de las funciones del backend.

Antes de captar usuarios reales:
1. En Supabase de pruebas, añade el origen exacto de GitHub Pages a **Authentication → URL Configuration → Site URL** y a **Redirect URLs**. Para un proyecto de repositorio, el origen esperado es `https://robertdeva.github.io/Universo-Geek/`; confirma la URL que GitHub Pages asigne antes de guardarla.
2. Prueba registro, confirmación de correo, inicio de sesión, recuperación y cierre de sesión con una cuenta nueva.
3. Verifica RLS con cuentas normales y confirma que ninguna cuenta puede consultar datos privados de otras personas.
4. Comprueba que el formulario de feedback no exponga información privada ni secretos.
5. Revisa las páginas de privacidad, cookies y términos antes de anunciar la demo públicamente.

## Activar GitHub Pages

El workflow `.github/workflows/deploy-demo-pages.yml` publica solo los archivos de la demo y los recursos estáticos necesarios. En el repositorio abre **Settings → Pages** y selecciona **GitHub Actions** como origen de despliegue. Después revisa **Actions**: la demo se considera publicada solo cuando el trabajo de despliegue termina correctamente y GitHub muestra la URL final.

## Separación del desarrollo

Los cambios de la plataforma continúan en `main` y en ramas de trabajo mediante pull requests. No se deben fusionar automáticamente los cambios de la demo a `main`; cualquier mejora que deba pasar a la plataforma se revisará y probará por separado.
