# Scripts por página

Este directorio está reservado para la lógica específica de cada página. La migración desde los scripts inline de los HTML debe hacerse de manera gradual, una página a la vez.

## Convención de nombres

- login.js: registro, inicio de sesión y recuperación.
- services.js: catálogo y formulario del marketplace.
- dashboard.js: pedidos del comprador/vendedor.
- admin.js: colas de moderación.

## Reglas

1. Carga primero config.js (en la raíz de assets/js) y después app.js; carga el script de página al final.
2. No copies la lógica de sesión/API en cada página. Usa window.UG.
3. Cada script de página debe limitarse a una pantalla y exponer la menor cantidad posible de variables globales.
4. Usa nombres descriptivos y comentarios para explicar reglas de negocio y decisiones no obvias.
5. Nunca incluyas secretos ni confíes en validaciones del navegador para permisos, precios o pagos.
6. Tras extraer un script, elimina el original inline solo después de comprobar que no se ejecuta dos veces y que el flujo completo funciona.
7. No extraigas varios scripts en una sola edición sin probar cada página.

Actualmente algunas páginas conservan JavaScript inline por compatibilidad con la versión reconstruida. Este directorio documenta la estructura objetivo para refactorizaciones futuras; no significa que todos esos archivos ya existan.
