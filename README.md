# Universo Geek

Plataforma en preparación para comunidad gamer, anime, manga y manhwa, enfocada en Latinoamérica y Estados Unidos.

## Estado del proyecto

La rama `main` se mantiene intacta. La reconstrucción de trabajo está en `audit/rebuild-2026-10-14`; **no se ha publicado ni desplegado el sitio**.

- [Guía para editar el código manualmente](docs/GUIA-CODIGO-HUMANO.md)
- [Asistente de ayuda y feedback](docs/ASISTENTE-Y-FEEDBACK.md)
- [Auditoría técnica](AUDITORIA-TECNICA-2026-10-14.md)
- [Revisión del paquete anterior y riesgos de pago](REVISION-PAQUETE.md)
- [Estado de implementación](docs/ESTADO-DE-IMPLEMENTACION.md)
- [Guía de preparación de Cloudflare Pages](docs/CLOUDFLARE-PAGES.md)
- [Informe de cambios de seguridad en Supabase](docs/DB-SECURITY-2026-10-14.md)
- [Configuración inicial del administrador](docs/ADMIN-BOOTSTRAP.md)

## Tecnologías y restricciones

- HTML, CSS y JavaScript nativo; sin npm, build tools, framework ni CDN externo.
- Supabase Auth/PostgREST para autenticación y futura integración de datos.
- Preparado para un futuro alojamiento estático en Cloudflare Pages.
- Interfaz adaptable a teléfono y ordenador.

## Incluido en esta fase

- Portada y navegación móvil.
- Registro, inicio de sesión y solicitud de recuperación de contraseña con Supabase Auth.
- Panel personal mínimo con comprobación de sesión.
- Páginas informativas de membresías, privacidad y cookies.
- Marketplace conectado a Supabase para listar servicios aprobados, enviar publicaciones pendientes y crear solicitudes de contratación sin procesar pagos.
- Panel personal con gestión del flujo de pedidos como comprador/vendedor; las transiciones se validan en la base de datos.
- Centro de moderación para servicios y anuncios de afiliados, con RPCs seguras y auditoría.
- Asistente local con respuestas limitadas a funciones verificadas del sitio y fallback explícito cuando no conoce la respuesta.
- Feedback protegido por Edge Function con validación de datos, límite de cinco envíos por IP hash/hora, protección de tamaño de solicitud y estadísticas administrativas agregadas.
- Página de resultado de pago que no confirma ni activa pagos.
- Cabeceras iniciales de seguridad y documentación técnica.

## Funciones que aún NO están listas

- La publicación, moderación de servicios/anuncios y gestión de pedidos básicos están conectadas a Supabase. El panel general para usuarios, asignación de roles y transacciones financieras todavía no está implementado.
- El panel general para usuarios, asignación de roles y transacciones todavía no está implementado. La moderación de servicios/anuncios sí está conectada.
- El rol moderator no puede ascender usuarios ni administrar pagos; los cambios de roles y pagos quedan restringidos.
- El checkout de membresías está desactivado. No se crean facturas ni se aceptan pagos.
- Las funciones Edge de QvaPay no se han desplegado y su formato de firma/webhook requiere confirmación oficial y pruebas.
- Formularios de contacto, newsletter, favoritos, compras digitales y contenido editorial no están conectados completamente. El feedback del asistente sí se guarda en Supabase.
- Los correos con dominio `.example` son marcadores de posición y deben reemplazarse.
- La política de privacidad/cookies es un borrador y requiere datos del operador y revisión legal.

## Configuración de Supabase

El archivo `assets/js/config.js` contiene la URL del proyecto y una clave publicable de cliente. No guardar jamás una clave `service_role`, un token de proveedor o un secreto en el frontend.

En Supabase Auth, antes de probar:
1. Permite solo las URL de redirección necesarias para el entorno de prueba.
2. Configura correo SMTP y recuperación de cuenta.
3. Habilita la protección contra contraseñas filtradas.
4. Prueba las políticas RLS con usuarios de distintos roles.
5. Revisa la protección contra contraseñas filtradas en Authentication → Security and Protection; Supabase la ofrece en Pro y superiores, así que en Free puede requerir una actualización de plan. No cambies de plan sin revisar el coste.

No ejecutar automáticamente los SQL incluidos en paquetes anteriores: comparar cada sentencia con las migraciones reales del proyecto y crear una copia de seguridad antes de cualquier cambio.

## Pagos

No activar pagos reales hasta que el backend valide directamente con el proveedor el estado, importe, moneda/referencia y la orden; debe ser idempotente y resistente a callbacks repetidos. Los secretos de QvaPay solo deben almacenarse como secretos de Edge Functions. No se deben activar membresías por una redirección del navegador.

## Pruebas locales

Desde la carpeta raíz, si tienes Python instalado:

```sh
python -m http.server 8080
```

Abre `http://localhost:8080`. Supabase Auth solo funcionará si el origen de prueba está permitido en sus ajustes. Esta rama no está certificada para producción.

## Publicación

No conectar ni desplegar Cloudflare Pages hasta recibir autorización explícita del propietario.