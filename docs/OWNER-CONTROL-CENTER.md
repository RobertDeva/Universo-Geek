# Centro privado del propietario

## Alcance y estado

Los cambios están aislados en `feature/owner-control-center`, creada desde `audit/rebuild-2026-10-14`. No se modifica `main`, no se despliega el sitio y no se ejecuta esta migración en Supabase automáticamente.

La página `owner.html` es solo la interfaz. La autorización efectiva está en `private.owner_allowlist` y `public.owner_dashboard_summary()`. El panel es de solo lectura: no procesa pagos, activa membresías ni publica en redes sociales.

## Instalación

1. Revisa el diff de esta rama antes de integrar.
2. Haz copia de seguridad y prueba la migración en un proyecto Supabase de desarrollo.
3. Ejecuta `supabase/migrations/20261014190000_owner_control_center.sql` en el SQL Editor de desarrollo.
4. En Supabase → Authentication → Users, identifica y verifica el UUID de tu cuenta personal. No uses el correo como autorización.
5. Tras confirmar el UUID, ejecuta manualmente esta plantilla sustituyendo ambos marcadores por el UUID válido:

```sql
insert into private.owner_allowlist (user_id, created_by, note)
values (
 'REEMPLAZA-POR-EL-UUID-VERIFICADO',
 'REEMPLAZA-POR-EL-UUID-VERIFICADO',
 'Cuenta personal del propietario'
);
```

La plantilla no se ejecuta tal cual: los marcadores deben sustituirse por un UUID real. La tabla no concede acceso a usuarios del navegador; solo un operador autorizado de base de datos puede gestionarla.
6. Inicia sesión con el propietario y abre `owner.html`. Comprueba que una cuenta normal y una de moderador no puedan acceder. El enlace no es una contraseña; la protección se hace en el servidor.
7. Antes de producción, verifica en el esquema real los estados de pago y la moneda de `digital_purchases.amount`.

## Métricas y cautelas

- Membresías: suma órdenes con `status = 'paid'` usando `amount_usd`.
- Productos digitales: suma compras con `status = 'paid'` usando `amount`. Solo puede etiquetarse USD si la columna representa USD de forma uniforme.
- También muestra conteos de membresías activas, servicios aprobados, pedidos y clics de afiliados.
- Los pedidos de servicios no son ingresos cobrados; los clics de afiliados no son comisiones.
- Las cifras son un resumen operativo, no contabilidad oficial. Un estado `paid` solo debe establecerlo un backend fiable tras verificar el proveedor o la cadena.

## Pruebas previas al despliegue

- [ ] El propietario puede ejecutar la RPC.
- [ ] Usuario sin allowlist recibe SQLSTATE `42501`.
- [ ] `anon` y `authenticated` no pueden leer ni escribir `private.owner_allowlist`.
- [ ] No hay secretos de proveedores en HTML/JavaScript.
- [ ] Órdenes pendientes no se incluyen en ingresos.
- [ ] Funciona en móvil y escritorio, sin CDN ni build tools.
- [ ] Migración probada en desarrollo y revisada contra el esquema real.
- [ ] Integración solo mediante Pull Request; `main` queda intacta.

## Fases posteriores

1. Exportación de estadísticas agregadas y saneadas para IA local en tu ordenador.
2. Bandeja de aprobaciones con confirmación explícita y registro de auditoría.
3. Integraciones oficiales de Telegram y Meta con permisos mínimos, revocación y revisión humana de acciones sensibles.
