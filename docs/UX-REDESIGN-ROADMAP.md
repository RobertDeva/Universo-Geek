# Hoja de ruta UX/UI — Universo Geek

## Rama de trabajo
- Rama: `feature/ux-redesign-phases`
- Base: `feature/owner-control-center`
- No modificar `main` directamente.
- Esta rama contiene mejoras de fase 1; no está publicada ni integrada.

## Fase 1 — Fundamentos visuales y navegación (incluida en esta rama)
- Sistema visual coherente con variables CSS locales.
- Tema oscuro y claro, con preferencia guardada localmente.
- Enlace para saltar al contenido, foco visible y respeto a `prefers-reduced-motion`.
- Menú móvil que se puede cerrar con Escape, al seleccionar un enlace o al tocar fuera.
- Búsqueda local de las secciones de la portada; no se presenta como búsqueda global.
- Ajustes responsive de tarjetas, formularios, cabecera y espaciado.

## Fase 2 — Descubrimiento y comunidad
- Buscador real de publicaciones, perfiles, servicios y catálogo con paginación.
- Filtros y ordenación accesibles.
- Colecciones y favoritos persistentes en Supabase.
- Notificaciones y preferencias de usuario.
- Las consultas deben respetar RLS y no exponer información privada.

## Fase 3 — Marketplace y monetización
- Perfiles de creadores, portafolio, reseñas verificadas y estados de pedido.
- Explicar claramente cuándo un flujo registra una solicitud y cuándo procesa dinero.
- Verificación de pagos exclusivamente en backend; nunca confiar en el estado enviado por el navegador.
- No activar pagos ni ejecutar migraciones de producción como parte del rediseño visual.

## Fase 4 — Administración y confianza
- Panel responsive de métricas y moderación.
- Registro de auditoría para acciones sensibles y aprobación explícita para reembolsos, permisos y cambios financieros.
- Controles de acceso aplicados en backend, no solo ocultando botones.

## Fase 5 — Calidad y rendimiento
- Probar anchos móvil, tableta y escritorio; navegación con teclado y lector de pantalla.
- Validar todos los enlaces y recursos locales.
- Revisar errores de JavaScript, contraste, formularios, estados vacíos y mensajes.
- Medir carga en redes lentas; comprimir imágenes y paginar listas.
- Verificar en un entorno de desarrollo antes de abrir una PR para integración.

## Restricciones técnicas
- HTML, CSS y JavaScript vanilla.
- Sin npm, bundlers ni CDNs obligatorios.
- No incluir claves privadas ni secretos en el navegador.
- No declarar una función completada hasta que haya sido probada.
