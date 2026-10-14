# Auditoría técnica — Universo Geek
Fecha: 2026-10-14
Rama: `audit/rebuild-2026-10-14`
Estado: revisión inicial; **no publicado**.

## Hallazgos verificados

### Repositorio GitHub
- El repositorio privado `RobertDeva/Universo-Geek` existe y la conexión dispone de permisos de administración.
- La rama principal `main` contiene únicamente el commit inicial, con `README.md` y `LICENSE`. No contiene el frontend, las funciones de Supabase, las migraciones ni la configuración de Cloudflare.
- Se creó esta rama de trabajo para mantener los cambios separados de `main`. No se ha modificado ni publicado `main`.

### Supabase conectado
- Proyecto: `khadcbgzziuwaxwptftw`, región `us-east-1`.
- Se observan 24 tablas en `public` y RLS está habilitado en todas ellas.
- Hay migraciones relacionadas con perfiles, marketplace, afiliados, membresías por rol y preparación de QvaPay.
- El trigger `membership_orders_sync_entitlement` sincroniza membresías cuando cambia el estado de la orden.
- No hay Edge Functions desplegadas. Por tanto, la creación de facturas, la validación del webhook y la consulta de estado de QvaPay no están operativas.
- El asesor de seguridad señala que la protección contra contraseñas filtradas está deshabilitada.

### Proyecto de archivos disponible fuera del repositorio
Se encontró en la biblioteca de trabajo el paquete `universo-geek-qvapay-preparado.zip`, con HTML/CSS/JS nativo, páginas de inicio, login, dashboard, administración, membresías, servicios, privacidad y cookies; SQL de preparación; y tres funciones de Edge Function propuestas para QvaPay. Ese paquete **no está versionado en este repositorio** y todavía necesita revisión y pruebas antes de considerarlo listo para producción.

## Bloqueadores antes de publicar

1. Incorporar al repositorio una versión revisada del proyecto estático y sus archivos de Supabase, manteniendo el historial existente.
2. Comparar cada migración del paquete con el estado real de la base de datos antes de ejecutar SQL; no volver a aplicar cambios solo porque estén presentes en un ZIP.
3. Revisar las funciones QvaPay contra el formato real del webhook de la cuenta y confirmar la autenticación de la firma, importe, referencia, estado, idempotencia y protección contra repetición.
4. Configurar credenciales QvaPay solo como secretos de Edge Functions; nunca en HTML, JavaScript del navegador, Git o chats.
5. Desplegar y probar las funciones en un entorno de prueba, con credenciales válidas y sin pagos reales inicialmente.
6. Habilitar protección contra contraseñas filtradas y revisar SMTP, redirect URLs, políticas RLS, buckets de Storage y permisos de funciones.
7. Completar pruebas con cuentas de usuario, moderador y administrador, así como registro, recuperación de contraseña, órdenes, disputas, boletín y favoritos.
8. Reemplazar los dominios de ejemplo en sitemap y metadatos, y completar los datos legales/contacto de privacidad.

## Decisiones de seguridad y despliegue

- No se han cambiado tablas ni datos de Supabase en esta auditoría.
- No se han desplegado Edge Functions.
- No se han creado facturas ni procesado pagos.
- No se ha conectado Cloudflare Pages a un despliegue.
- **No publicar el sitio**: mantener todos los cambios en ramas de trabajo hasta que el propietario lo autorice explícitamente.
