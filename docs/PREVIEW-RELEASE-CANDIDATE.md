# Vista previa de la candidata a lanzamiento

- Rama: preview/release-candidate-2026-10-16
- Base de código: main, con la integración más reciente.
- Configuración: usa el proyecto Supabase de pruebas, no el proyecto principal.
- Estado: rama de vista previa; no fusionar en main.

## Reglas

1. Esta rama existe solo para pruebas de navegador en Cloudflare Pages.
2. Nunca copiar su assets/js/config.js a main.
3. No introducir claves secretas ni service_role en el navegador.
4. No activar pagos ni usar transacciones reales; QvaPay y las membresías pagadas siguen desactivados.
5. Configurar Cloudflare para desplegar esta rama como preview únicamente. Mantener la rama de producción en main y los despliegues automáticos de producción desactivados.
6. Después del despliegue, usar la URL exacta que Cloudflare reporte para configurar la URL de redirección permitida en Supabase Auth.
7. La rama audit/rebuild-2026-10-14 se conserva para diagnóstico histórico; no debe fusionarse en bloque.

## Prueba manual requerida

- Abrir la URL de preview generada por Cloudflare.
- Crear una cuenta con un correo que controles.
- Completar la confirmación por correo si está activada.
- Verificar en el proyecto de pruebas que el usuario se creó.
- Probar inicio de sesión, recuperación y cierre de sesión.
- Confirmar que la URL final no redirige al proyecto principal ni a una URL no permitida.
