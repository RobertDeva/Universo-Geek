# Lista de preparación para lanzamiento — 16 de octubre de 2026

Esta lista distingue cambios de código integrados de tareas que requieren acceso a servicios alojados o pruebas manuales. **El sitio no está certificado para publicación. No se ha realizado un despliegue público en esta revisión.**

## Cambios de código verificados

- [x] PR #10 integrado: eliminar declaraciones de funciones QvaPay inexistentes; CI de seguridad de configuración aprobado.
- [x] PR #15 integrado: mejorar el modo registro/inicio de sesión y manejo de errores; comprobación estática de autenticación aprobada.
- [x] PR #14 integrado: endurecer RPC administrativas y denegar acceso del navegador a la tabla de límites de feedback.
- [x] Reproducción de todas las migraciones en un Supabase local desechable aprobada en CI.
- [x] Mantener HTML/CSS/JavaScript nativo: sin npm, bundler ni CDN externo para servir el sitio.
- [x] PR #17 integrado: base de GeekPoints y pruebas de reglas, concurrencia e idempotencia aprobadas; todas las reglas siguen deshabilitadas.
- [x] PR #18/#19 integrados: búsqueda, filtros y ordenación del marketplace; comprobaciones estáticas del sitio aprobadas.
- [x] PR #20 integrado: índice de feedback por usuario y nota de compatibilidad histórica.
- [x] PR #21 integrado: las órdenes de pago quedan en solo lectura para roles del navegador; la migración pasó la reconstrucción local.

## Bloqueadores de seguridad en el Supabase principal

- [ ] Autorizar y aplicar las migraciones nuevas de seguridad, permisos de órdenes e índice al proyecto Supabase principal en una ventana controlada.
- [ ] Ejecutar de nuevo Security Advisor y confirmar que admin_site_feedback_stats() ya no se expone como SECURITY DEFINER.
- [ ] Confirmar que site_feedback_rate_limits tiene la política explícita de denegación de acceso de cliente y privilegios revocados.
- [ ] Revisar la opción de protección contra contraseñas filtradas en Authentication → Security and Protection; puede depender del plan. No actualizar el plan sin revisar el coste.
- [ ] Probar RLS con cuentas separadas de usuario, moderador y administrador.
- [ ] Confirmar que la cuenta administradora existe y que la guía de bootstrap es correcta para el proyecto actual.

## Prueba de autenticación que necesita intervención humana

- [ ] Confirmar en Supabase Auth las URL permitidas de redirección para la vista previa exacta y para el origen de publicación autorizado.
- [ ] Confirmar SMTP y entrega de correo y recuperación de contraseña.
- [ ] Abrir la vista previa de Cloudflare y probar registro con una dirección de correo que controles.
- [ ] Confirmar si aparece un usuario en Authentication → Users; si exige confirmación, completar el enlace recibido.
- [ ] Probar inicio de sesión, cierre de sesión, recuperación y renovación de sesión.
- [ ] Probar el panel personal desde el mismo origen. No usar una vista previa que apunte a la base principal sin autorización.

Evidencia actual: los logs de Auth muestran una solicitud de registro exitosa desde GitHub Pages, pero no una solicitud desde la vista previa de Cloudflare. La prueba de Cloudflare sigue pendiente.

## Funciones y producto

- [ ] Verificar la conexión del proyecto Cloudflare Pages al repositorio y confirmar que los despliegues automáticos de producción siguen desactivados. La configuración actual de Cloudflare no se ha podido verificar desde esta sesión.
- [ ] Confirmar que la vista previa se genera desde la rama de pruebas y el commit esperado.
- [ ] Probar el marketplace: listado aprobado, envío pendiente, moderación, contratación y transiciones de pedido.
- [ ] Probar el asistente y feedback; el proyecto Supabase de pruebas no tiene Edge Functions desplegadas actualmente.
- [ ] Completar panel general de usuarios/roles y transacciones, si se requiere para el alcance de lanzamiento.
- [ ] Sustituir todos los correos .example por contactos válidos y autorizados.
- [ ] Completar datos del operador y revisión legal de privacidad, cookies y términos.

## Pagos

- [x] QvaPay se mantiene desactivado; la configuración ya no declara funciones que no existen.
- [ ] No habilitar membresías pagadas hasta implementar y probar creación de factura, consulta de estado y webhook auténtico, con verificación servidor a servidor, importe/referencia, idempotencia y protección contra repetición.
- [ ] No marcar una orden como pagada por una redirección del navegador ni por datos proporcionados por el cliente.
- [ ] No habilitar pagos manuales, wallets ni GeekPoints canjeables hasta revisar conciliación, fraude, disputas y reembolsos.

## Publicación

- [ ] Ejecutar pruebas de navegador en teléfono y escritorio: navegación, accesibilidad, enlaces, formularios y errores.
- [ ] Revisar cabeceras de seguridad y CSP; mover scripts inline a archivos locales antes de retirar unsafe-inline.
- [ ] Confirmar que todas las páginas y los datos legales están completos.
- [ ] Obtener autorización expresa para desplegar/publicar. No publicar automáticamente al cerrar PRs.
