# Preparación de Cloudflare Pages y QvaPay

Estado: preparación en rama de pruebas; no se ha creado un proyecto Cloudflare Pages ni se ha publicado el sitio.

## Rama y origen

- Repositorio: `RobertDeva/Universo-Geek`
- Rama de pruebas: `audit/rebuild-2026-10-14`
- Directorio raíz de publicación: `/`
- Tipo de proyecto: sitio estático HTML/CSS/JavaScript; no usa npm ni necesita comando de build.
- Archivo de entrada: `index.html`

En Cloudflare Pages, elegir **Connect to Git** (no Direct Upload si se quiere mantener despliegue conectado al repositorio), conectar GitHub y seleccionar esta rama para la primera vista previa. Configurar el directorio de salida como `/` o dejarlo vacío si la interfaz lo permite y usa la raíz. No publicar desde `main` durante esta fase.

## Páginas de regreso QvaPay (solo interfaz)

- URL de éxito propuesta: `https://<dominio-pages>/pago-exitoso.html`
- URL de cancelación propuesta: `https://<dominio-pages>/pago-cancelado.html`

Estas páginas existen para informar al usuario, pero **no verifican ni confirman un pago**. No activar membresías por parámetros de URL ni por el regreso del navegador. Reemplazar `<dominio-pages>` por el hostname real solo después de que Cloudflare publique la vista previa y se haya comprobado que ambas rutas cargan.

## Callback/webhook

No introducir una URL ficticia en QvaPay. La URL definitiva debe apuntar a una Edge Function de Supabase realmente desplegada y validada, por ejemplo una ruta con el formato:

`https://<project-ref>.supabase.co/functions/v1/<nombre-real-de-la-funcion>`

Esto es solo un patrón ilustrativo, no una URL lista para pegar. Antes de registrar el callback se debe:
1. confirmar con la documentación vigente de QvaPay el formato de firma y el esquema real del webhook;
2. verificar la transacción con el API autenticado de QvaPay en backend;
3. comprobar referencia, importe, moneda, estado y correspondencia con la orden pendiente;
4. hacer que la transición a pagada sea atómica e idempotente;
5. probar eventos duplicados, atrasados, malformados y de firma inválida;
6. mantener desactivado el checkout mientras esas pruebas no pasen.

Guardar el secreto de QvaPay solo como secreto de la Edge Function de Supabase. Nunca incluirlo en HTML, JavaScript del navegador, GitHub, ni variables públicas del frontend.

## Lista de pruebas antes de compartir la URL

- [ ] La página inicial carga con CSS y JavaScript.
- [ ] Las páginas enlazadas existen y no hay enlaces rotos.
- [ ] Se revisa en móvil y escritorio.
- [ ] Auth de Supabase tiene la URL de preview en Redirect URLs y se prueba recuperación de contraseña.
- [ ] Se verifican RLS y permisos de tablas desde una cuenta no administrativa.
- [ ] Las páginas de éxito/cancelación no activan membresías.
- [ ] No hay secretos de backend en archivos públicos.
- [ ] El proveedor y el callback se prueban en entorno controlado.
- [ ] Las políticas legales reflejan al operador real y la jurisdicción aplicable.
- [ ] El propietario autoriza expresamente cualquier publicación pública o fusión a `main`.

## Límites conocidos

La existencia de las páginas estáticas no significa que el marketplace, la autenticación, la moderación o los pagos estén listos para producción. La conectividad desde Cuba depende de la red y de los proveedores externos; debe probarse desde las redes de destino.
