# Entorno de pruebas aislado — Universo Geek

Fecha: 2026-10-18

## Propósito

Esta rama prepara una vista previa de autenticación que apunta exclusivamente al proyecto Supabase de pruebas `tvjglznjntegujfczljp`. No usarla para datos reales ni para producción.

## Cambios incluidos

- `assets/js/config.js` usa la URL y la clave publishable del proyecto de pruebas.
- No se modificó `main` ni la configuración de producción.
- No se desplegaron funciones Edge ni se activaron pagos.
- La clave incluida es publishable y está pensada para el navegador; no incluir claves secretas ni `service_role`.

## Preparación de Supabase antes de probar

En el proyecto **Universo Geek (BdDdP)** (`tvjglznjntegujfczljp`):

1. Abrir **Authentication → URL Configuration**.
2. Confirmar que el Site URL corresponde al origen de la vista previa que se va a utilizar.
3. Añadir a **Redirect URLs** el callback exacto de la vista previa, por ejemplo `https://robertdeva.github.io/Universo-Geek/login.html`, y el patrón de ruta de ese mismo origen si se usa en la interfaz. No añadir dominios comodín amplios.
4. Revisar **Authentication → Providers → Email**: confirmar si se exige confirmación de correo y que las plantillas apunten a una URL permitida.
5. No modificar SMTP, proveedor de correo ni políticas de producción como parte de esta prueba.

No se puede garantizar la entrega del correo hasta verificar el SMTP y los límites de envío en el propio proyecto de pruebas.

## Secuencia de pruebas manuales

Utilizar una dirección de correo controlada por la persona que prueba, preferiblemente un alias nuevo. No enviar repetidamente solicitudes para el mismo correo.

1. Abrir `login.html` desde el despliegue de esta rama.
2. Confirmar que el formulario inicia en modo **Entrar** y que el campo de referido está oculto.
3. Cambiar a **Crear cuenta**; confirmar que el campo de referido aparece y es opcional.
4. Enviar un correo válido y una contraseña que cumpla la política del proyecto.
5. Confirmar que la interfaz muestra el resultado de Supabase; no asumir que un mensaje de éxito significa que la cuenta ya está confirmada.
6. En **Authentication → Users**, comprobar que el usuario aparece en el proyecto de pruebas. No copiar tokens ni datos personales a issues.
7. Si se exige confirmación, abrir el correo y seguir el enlace. Confirmar el estado de correo en Supabase.
8. Iniciar sesión con esa cuenta y comprobar que llega al panel personal.
9. Probar recuperación de contraseña y revisar la entrega del correo.
10. Probar un correo inválido, una contraseña insuficiente y un correo ya registrado; los errores deben ser comprensibles y no dejar botones bloqueados.
11. Comprobar que el usuario de prueba no tiene permisos de administrador ni puede leer/escribir datos de otros usuarios.
12. Al terminar, eliminar la cuenta de prueba desde el proyecto de pruebas si no se necesita conservarla.

## Criterios de aprobación

- La URL y clave utilizadas pertenecen a `tvjglznjntegujfczljp`, no a producción.
- El registro crea un usuario en el proyecto correcto.
- La confirmación de correo funciona cuando está activada.
- El login solo crea sesión tras autenticación válida.
- Recuperación funciona y no revela si una cuenta existe.
- RLS impide acceder a datos de otros usuarios.
- No hay errores de consola que rompan el flujo.

## Pendientes no resueltos automáticamente

- La URL real de despliegue de esta rama debe confirmarse en GitHub Pages/Cloudflare Pages; no se presume que la rama ya esté desplegada.
- Las URL permitidas de Auth deben configurarse en el panel de Supabase de pruebas.
- La entrega real del correo requiere comprobación manual.
- No realizar pruebas de navegador en producción, ni habilitar pagos, ni fusionar esta rama a `main` como parte de este procedimiento.
