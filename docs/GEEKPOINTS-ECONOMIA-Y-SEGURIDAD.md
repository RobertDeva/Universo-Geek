# GeekPoints — fase fundacional

## Estado
Esta migración crea el libro mayor y la solicitud de canje, pero no activa recompensas ni membresías. Los planes están deshabilitados por defecto. No aplicar a producción sin revisar el esquema, probar en staging y aprobar expresamente. No habilitar cobros: los pagos siguen separados.

## Límites por usuario y plan en ventana móvil de 24 meses
| Código | Máximo | Coste piloto GP | Estado |
|---|---:|---:|---|
| geek | 2 | 1.000 | Deshabilitado |
| otaku_pro | 1 | 2.500 | Deshabilitado |
| creator | 0 | 5.000 | Deshabilitado/no canjeable |

Los códigos deben cotejarse con los planes comerciales reales antes de activar nada. El código creator existe en la base por compatibilidad con roles y no concede rol de creador. Geek Creator requiere invitación o solicitud aprobada, actividad original y afiliación activa. El canje no activa una membresía; solo crea solicitud pendiente y reserva GP. La ventana es móvil: created_at >= now() - interval '24 months'. Pendientes, aprobados y cumplidos cuentan para prevenir solicitudes simultáneas.

## Economía piloto propuesta (reglas deshabilitadas)
- Referido verificado: 50 GP; máximo 10 por usuario en 30 días.
- Primera contribución original válida de referido: 25 GP una vez tras aprobación.
- Publicación original aprobada: 20 GP una vez por publicación.
- Vistas válidas: 1 GP por 10 vistas únicas válidas; tope 500 GP por publicación y 1.500 GP por autor en 30 días.
- Participación destacada: 1–5 GP con revisión humana y presupuesto mensual.
- Gastos editoriales sugeridos: artículo 10 GP; guía/análisis 20 GP; destacado 40 GP.

Son hipótesis, no promesas ni equivalencias monetarias. GeekPoints no se transfieren, venden, retiran ni convierten a moneda/token. No se implementa token blockchain.

## Protección económica
1. Calcular coste marginal, comisiones, soporte, fraude e impuestos antes de habilitar canjes.
2. El presupuesto de recompensas debe derivarse del margen bruto disponible.
3. El canje no activa membresía ni confirma pago. El fulfillment requiere otra fase revisada.
4. No confiar en vistas o referidos reportados por el navegador.
5. El ledger usa event_key único; futuras correcciones serán asientos compensatorios.
6. Congelar cuentas sospechosas y auditar. Moderadores no deben ajustar saldos.
7. Antes de habilitar canjes reales, implementar reembolso transaccional e idempotente para solicitudes rechazadas.

## RLS
Los usuarios autenticados leen únicamente sus filas (o admin mediante la función existente public.is_admin). No hay escrituras directas desde el navegador en saldo, ledger, reglas, límites o auditoría. La RPC valida sesión, saldo, cuenta congelada y límite por plan; solo crea solicitud pendiente. service_role nunca va en HTML/JS público.

## Rama y aceptación
Rama feature/geekpoints-foundation, basada en audit/rebuild-2026-10-14. Próximas fases separadas: referidos, contenido/vistas, resolución/reembolso, Geek Creator y panel. En staging probar saldo insuficiente, reintentos, concurrencia, límites separados, plan deshabilitado, cuenta congelada, aislamiento RLS entre usuarios y ausencia de activación automática. No aplicar a producción ni fusionar a main hasta revisión.
