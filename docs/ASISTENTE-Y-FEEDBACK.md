# Asistente de ayuda y feedback

## Qué hace

El botón «Ayuda y feedback» aparece en las páginas del sitio. El asistente responde preguntas frecuentes sobre:
- Registro, inicio de sesión y recuperación.
- Marketplace y publicación de servicios.
- Membresías y estado actual de pagos.
- Moderación, privacidad y cookies.
- Compatibilidad móvil y envío de sugerencias.

El bot actual es **local y basado en reglas**. No usa IA generativa ni consulta servicios externos para responder. Sus respuestas se limitan a funciones verificadas en las páginas del repositorio: registro y recuperación, servicios, membresías, pagos, feedback, políticas y moderación. Si no reconoce una pregunta o detecta que mezcla temas, lo dice y ofrece el formulario en vez de inventar una respuesta. Para editarlo, modifica el arreglo `FAQ` en `assets/js/help-bot.js`; cada entrada define palabras clave y una respuesta. Verifica la página y el backend antes de añadir afirmaciones nuevas.

## Cómo funciona el feedback

El formulario permite elegir categoría, valoración opcional, comentario y correo opcional. También registra la ruta de la página para dar contexto. Los datos se guardan en `public.site_feedback` mediante Supabase.

- El comentario debe tener entre 5 y 2000 caracteres.
- El correo es opcional; pide solo los datos necesarios.
- El usuario autenticado queda asociado a su UUID; el usuario anónimo puede enviar sin identificarse.
- El formulario no debe recibir contraseñas, documentos, datos bancarios ni información sensible.
- La tabla tiene RLS. Los navegadores ya no pueden insertar directamente: el envío pasa por la Edge Function `submit-site-feedback`, que valida los campos y la sesión si existe, aplica un máximo de cinco envíos por IP hash en una ventana de una hora y llama a una función SQL con privilegios mínimos.
- La dirección IP sin procesar no se guarda; la función usa un hash con sal basada en el secreto del servidor. Los hashes de limitación inactivos se eliminan después de 30 días.
- Solo un administrador puede leer los comentarios y actualizar su estado. El RPC `admin_site_feedback_stats` devuelve estadísticas agregadas para la bandeja administrativa.
- El panel de administración muestra hasta 100 comentarios recientes y permite marcar: nuevo, en revisión, planificado, resuelto o cerrado.
- El bot no promete una respuesta humana ni un plazo de resolución.

## Dónde revisar los comentarios

Inicia sesión con una cuenta con rol `admin` y abre `admin.html`. En «Feedback de usuarios» podrás leer los comentarios y actualizar el estado. Los moderadores no tienen acceso a esta bandeja por defecto.

Si la bandeja no carga, revisa:
1. Que la cuenta tenga rol `admin` en Supabase.
2. Que la migración `20261014092528_site_feedback_for_help_bot.sql` y `20261014094251_admin_feedback_status_workflow.sql` estén aplicadas.
3. Que el navegador pueda acceder a Supabase y que las políticas RLS sigan activas.
4. Que la Edge Function `submit-site-feedback` esté activa y que la configuración de funciones de Supabase incluya `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` en el entorno gestionado por Supabase. No copies la clave de servicio al frontend ni al repositorio.

## Límites y mejoras futuras

- Las respuestas son estáticas y no aprenden automáticamente de los mensajes.
- El honeypot y el límite del servidor reducen spam, pero no son una defensa completa contra ataques distribuidos. Si se detecta abuso, añadir CAPTCHA accesible o una capa antiabuso adicional y revisar los límites.
- La tabla almacena feedback y correo opcional; limita el acceso, define una política de conservación y revisa los textos legales antes del lanzamiento.
- No hay notificaciones por correo ni clasificación automática.
- Las sugerencias deben revisarse por una persona; no se aplican cambios al sitio automáticamente.

## Probarlo sin publicar

Abre el proyecto en un servidor local sencillo, inicia sesión con un usuario normal y envía un comentario de prueba. Después inicia sesión con una cuenta administradora y comprueba que aparece en la bandeja. No uses datos personales reales durante la prueba. Borra los comentarios de prueba desde un proceso administrativo autorizado si ya no se necesitan.


## Estado de veracidad
El asistente debe responder únicamente con hechos comprobados en las páginas y flujos implementados. Si una pregunta no coincide con una respuesta documentada, debe admitir que no conoce la respuesta y ofrecer el formulario de feedback. El checkout de membresías permanece desactivado mientras la cuenta comercial de QvaPay está pendiente. No publicar el sitio durante esta tarea.
