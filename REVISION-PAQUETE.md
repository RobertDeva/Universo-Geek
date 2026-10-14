# Revisión del paquete de implementación

Fecha: 2026-10-14
Paquete revisado: `universo-geek-qvapay-preparado.zip` (archivo de trabajo fuera del repositorio).
Alcance: inspección estática. No equivale a una prueba funcional ni autoriza el despliegue.

## Comprobaciones realizadas

- El paquete incluye páginas HTML de portada, login, dashboard, administración, membresías, resultado de pago, servicios, privacidad y cookies.
- El frontend usa HTML/CSS/JavaScript nativo y no se detectaron referencias a CDNs externos en HTML/CSS/JS.
- `node --check` pasó para los seis archivos JavaScript del paquete.
- El archivo `assets/js/config.js` contiene la URL del proyecto Supabase y una clave publicable; no contiene una clave `service_role`.
- El sitemap, robots y metadatos Open Graph aún usan `universogeek.example`. Deben actualizarse cuando exista un destino público elegido.
- Los tres archivos de Edge Functions QvaPay están presentes en el ZIP, pero el proyecto Supabase actualmente no tiene ninguna Edge Function desplegada.

## Revisión preliminar de QvaPay

El código intenta validar la sesión de Supabase antes de crear una orden, fija los precios en servidor, guarda una factura pendiente y consulta la transacción con las credenciales de servidor. Tanto webhook como consulta de estado comparan referencia e importe y actualizan solo órdenes que siguen pendientes, lo que ayuda con la idempotencia.

No se debe considerar seguro ni operativo hasta resolver estas comprobaciones:

1. Confirmar en la documentación oficial y en una notificación real de la cuenta qué encabezados, bytes firmados y formato exacto utiliza el webhook de facturas. El código presupone `x-qvapay-signature: sha256=...` y un timestamp opcional; no debe habilitarse públicamente hasta verificarlo.
2. Confirmar que la consulta de transacción y sus campos (`transaction_uuid`, `remote_id`, `amount`, `status`) coinciden con la respuesta real de QvaPay. La función debe fallar de forma cerrada si el esquema es inesperado.
3. Asegurar que la creación de factura no deje una orden sin resolver si QvaPay crea la factura pero falla el guardado de la referencia; incorporar reconciliación/soporte y no inducir al usuario a pagar dos veces.
4. Probar concurrencia: webhook y consulta de estado pueden ejecutarse al mismo tiempo. La transición debe ser atómica en base de datos, idealmente mediante una función SQL restringida que compruebe estado, referencia, importe y proveedor en una sola operación.
5. Confirmar límites de frecuencia, expiración y manejo de órdenes caducadas; evitar que un callback antiguo active una orden ya cancelada o expirada.
6. La firma HMAC no debe basarse en una suposición sobre el secreto. Confirmar si QvaPay realmente firma con el App Secret y si incluye timestamp/cuerpo en el cálculo. Si la documentación de la cuenta no lo confirma, usar el webhook solo como señal y exigir consulta autenticada al API de QvaPay antes de modificar la orden.
7. Verificar que `verify_jwt` esté habilitado para `qvapay-create-invoice` y `qvapay-check-status`, y deshabilitado para el webhook únicamente cuando la firma del proveedor esté implementada y probada correctamente.

## Estado de seguridad de Supabase

La comprobación del proyecto conectado confirmó que no hay Edge Functions desplegadas. El asesor de seguridad también devuelve `auth_leaked_password_protection`: la protección contra contraseñas filtradas está deshabilitada. Activarla en Auth antes de abrir registros al público.

## Decisión

**No desplegar las funciones de pago todavía.** La estructura del frontend puede servir como base de trabajo, pero primero debe importarse al repositorio, revisarse contra el esquema real y probarse en una rama. No se modificó la base de datos ni se publicó el sitio.
