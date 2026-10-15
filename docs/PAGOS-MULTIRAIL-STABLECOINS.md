# Pagos multivía con liquidación en stablecoins — Universo Geek

Fecha de diseño: 2026-10-14  
Rama: `feature/multirail-stablecoin-checkout`  
Estado: diseño y base de datos preparatoria; **no hay cobros activos ni despliegue autorizado**.

## Objetivo y restricciones

Prioridades de entrada: tarjetas, PayPal y transferencias/pagos locales. Activos de destino: USDC y USDT. Redes objetivo: Ethereum, Solana y BNB Smart Chain (BSC). Frontend: HTML, CSS y JavaScript nativo, sin build tools ni CDNs. Backend: Supabase Edge Functions + Postgres con RLS.

No tener una cuenta bancaria propia no garantiza que un procesador acepte al titular o permita liquidar a una wallet. El sistema debe mostrar solo los métodos que estén aprobados y configurados en el entorno. No se deben usar cuentas personales de terceros ni falsear país, identidad o forma jurídica para superar el onboarding.

## Decisión de arquitectura

Crear un adaptador de pagos independiente del proveedor. No se codifica un proveedor como ruta obligatoria ni se acoplan los estados de una marca al estado interno del pedido.

### Rutas de cobro

1. **Tarjeta → proveedor de pagos → liquidación admitida.** El proveedor puede liquidar fiat, mantener un saldo interno o —si lo ofrece expresamente para la cuenta, país y contrato— liquidar en stablecoin. Si solo liquida fiat a una cuenta bancaria, esta ruta queda desactivada hasta que exista un destino aceptado. No asumir que un procesador de tarjetas envía USDC/USDT a cualquier wallet.
2. **PayPal → saldo PayPal → conversión/transferencia posterior solo si es permitida.** PayPal Checkout no equivale a una pasarela de liquidación USDC/USDT en Ethereum, Solana o BSC. La conversión manual con fondos del titular es una operación de tesorería separada, sujeta a disponibilidad, elegibilidad y términos de PayPal; no se anunciará como conversión instantánea del checkout.
3. **Transferencia/pago local → confirmación de fondos → conversión.** Mientras no haya API de pago/liquidación compatible, esta ruta es manual: referencia única, instrucciones por país, revisión por administrador y activación solo tras confirmar el abono. Un recibo o captura no prueba que los fondos estén disponibles.
4. **Cripto directa (fase posterior).** Dirección y red exactas por orden, vigilancia on-chain, confirmaciones y validación de activo/contrato. No se debe convertir automáticamente sin cotización firme, límite de slippage y comprobación del resultado en cadena.

### Conversión y destino

- La orden fija antes de pagar: activo destino (USDC o USDT), red (Ethereum, Solana o BSC) y dirección de recepción validada por un administrador.
- El proveedor debe confirmar por contrato/API que admite el método de entrada, el país del titular, el activo, la red y el pago a una wallet externa. Si no existe una ruta aprobada, se informa «no disponible» y no se cobra.
- La conversión es un paso separado: guardar cotización, vencimiento, comisiones, importe neto esperado, identificador de operación y hash de salida. No prometer un importe neto fijo antes de recibir una cotización válida.
- Validar tokens por contrato oficial y red; el nombre USDC/USDT no basta. No mezclar USDC nativo con representaciones puenteadas sin política explícita.
- En BSC, usar el identificador de cadena correcto; Ethereum y BSC comparten formato de dirección EVM pero no son la misma red. Solana requiere su propio validador de direcciones y explorador.
- Los fondos en una wallet controlada por el titular siguen bajo control/custodia de ese titular. Esto no debe describirse como «sin custodia» solo porque no se use una pasarela tradicional.

## Proveedores y dependencias externas imprescindibles

No se fija todavía una marca como proveedor de producción. Antes de seleccionar uno, solicitar confirmación escrita sobre:

- incorporación de persona física/proyecto no constituido y países admitidos;
- requisitos de KYC/KYB, titular real, actividad permitida, origen de fondos y restricciones de sanciones;
- aceptación de tarjetas/PayPal/transferencias locales;
- forma de liquidación, titularidad de la wallet y redes/token disponibles;
- reservas, reembolsos, chargebacks, congelaciones, límites, comisiones y plazos;
- soporte para webhooks firmados, consulta de pago por API e idempotencia;
- autorización para usar el servicio en membresías y marketplace, incluidos pagos a vendedores si se habilitan después.

Stripe documenta países admitidos y requisitos adicionales para abrir cuentas transfronterizas, que pueden incluir entidad legal, identificación fiscal, domicilio y cuenta bancaria local. Sus productos de stablecoin no deben confundirse automáticamente con la liquidación de Stripe Payments. PayPal indica que las funciones cripto solo están disponibles para ciertos tipos de cuentas elegibles; comprar/transferir cripto desde PayPal no demuestra que PayPal Checkout liquide directamente en USDC/USDT a las tres redes objetivo. Ver referencias oficiales al final.

Dependencias técnicas:
- Supabase Auth, Postgres/RLS y Edge Functions para crear órdenes, recibir webhooks y reconciliar estados.
- Un proveedor de pago compatible con cada método habilitado; no necesariamente el mismo proveedor para todos.
- Un proveedor de conversión/liquidez o DEX/aggregator que soporte exactamente el par y red, con política de riesgo y comprobación de transacción.
- RPC/indexador fiable para cada red si se aceptan pagos cripto directos; opcional en el primer lanzamiento si todos los métodos tradicionales son verificados por un proveedor.
- Monitorización y alertas para webhooks fallidos, pagos sin conciliar, conversiones atascadas y saldos inesperados.

## Modelo de datos propuesto

La migración preparatoria `payment_attempts` registra intentos asociados a `membership_orders`: proveedor/método, referencia externa, idempotencia, estado normalizado, importe y moneda de entrada, activo/red/dirección de destino, importes netos, identificadores de conversión y hashes. El navegador solo puede leer sus propios intentos; creación y cambios de estado pertenecen al backend. No se guarda información de tarjetas ni datos sensibles innecesarios del proveedor.

Estados internos recomendados:
`created`, `awaiting_payment`, `payment_detected`, `payment_confirmed`, `conversion_pending`, `settlement_confirming`, `paid`, `underpaid`, `expired`, `failed`, `refunded`, `chargeback`, `under_review`.

Las transiciones deben ser monotónicas o explícitamente compensadas; eventos repetidos no deben duplicar crédito ni activar dos veces una membresía. Un pago de tarjeta puede revertirse por chargeback aun después de la confirmación inicial.

## Verificación de pagos y seguridad

1. El backend obtiene el precio desde configuración confiable; ignora el importe enviado por el navegador.
2. Genera una referencia e idempotency key únicos y registra el intento antes de redirigir al proveedor.
3. Valida autenticación y propiedad del pedido; aplica límites de frecuencia.
4. El webhook valida la firma sobre el cuerpo original según la documentación oficial del proveedor, compara timestamp/ventana anti-replay si está soportado y almacena el ID del evento con unicidad.
5. El webhook es solo una señal: consulta también la API autenticada del proveedor para confirmar estado final, importe, moneda, referencia y beneficiario.
6. La actualización del intento y de la orden se realiza atómicamente en Postgres, condicionada al estado anterior; eventos duplicados/concurrentes no duplican el efecto.
7. Para conversión, verificar cotización, monto mínimo, comisión/slippage, hash, destino, red, token/contrato y confirmaciones. No usar un hash enviado por el usuario como prueba suficiente.
8. Solo una transición backend validada a `paid` activa la membresía. La redirección del navegador no modifica el estado financiero.
9. Los secretos de proveedor, webhook, RPC privado y claves de conversión se guardan como secretos de Edge Functions; nunca en frontend, migraciones, logs o Git. Nunca guardar frases semilla/llaves privadas en Supabase.
10. Separar permisos: admin puede revisar operaciones; moderator no puede cambiar fondos, liquidaciones ni roles. Auditar toda acción manual con actor, razón y fecha.
11. Política de reembolso: definir si se reembolsa fiat, stablecoin o crédito; resolver chargebacks, pagos parciales, pagos tardíos y conversiones irreversibles antes de producción.
12. KYC/AML, impuestos, sanciones, licencias de transmisión/servicios financieros, protección al consumidor y términos del marketplace requieren revisión legal para los países realmente atendidos. No lanzar pagos a usuarios o regiones no aprobadas.

## Plan de implementación por etapas

### Fase 0 — Esta rama
- Documentar arquitectura, dependencias, límites y controles.
- Añadir una tabla privada de intentos de pago sin habilitar cobros.
- Mantener el checkout desactivado y no desplegar funciones ni aplicar migraciones al proyecto activo.

### Fase 1 — Sandbox y selección de proveedores
- Consultar onboarding y elegibilidad real para tarjeta, PayPal y cada método local.
- Elegir proveedor solo si confirma método + país + liquidación wallet/stablecoin + red/token.
- Obtener credenciales sandbox y documentación oficial de webhooks.
- Definir wallets de tesorería por red, responsables y procedimiento de recuperación. No publicar direcciones de producción en esta fase.

### Fase 2 — Backend y pruebas
- Implementar adaptador por proveedor: `createPayment`, `verifyPayment`, `parseWebhook`, `requestRefund` (si aplica).
- Implementar reconciliador periódico y cola de incidencias.
- Probar webhook falso, firma inválida, eventos duplicados, orden ajena, importe/moneda incorrectos, pago tardío, concurrencia, fallo del proveedor, conversión fallida y chargeback.
- Aplicar migración primero en proyecto Supabase de desarrollo; revisar RLS, grants, índices y SQL advisors.

### Fase 3 — Beta cerrada
- Activar solo un método y un país que el proveedor haya aprobado; usar cantidades pequeñas y, cuando sea posible, sandbox/testnet.
- Comparar ledger interno con panel del proveedor y explorador.
- Revisión manual diaria y límites bajos de operación.

### Fase 4 — Producción gradual
- Habilitar otros métodos/países/redes uno a uno, después de verificación y pruebas.
- Habilitar membresías tras confirmación final del proveedor y, si aplica, liquidación confirmada en stablecoin.
- Publicar términos, política de reembolso, privacidad, tarifas y tiempos de confirmación.
- Despliegue y merge requieren aprobación explícita del propietario.

## Criterios de aceptación

- No existe ruta que permita al navegador marcar un pedido como pagado.
- Un webhook sin firma válida no modifica datos.
- Eventos repetidos y solicitudes concurrentes solo producen un efecto financiero.
- El importe/moneda/orden/proveedor/beneficiario se comprueban contra la API autenticada.
- Un método aparece en checkout solo si está configurado y aprobado para el entorno y destino.
- La membresía no se activa antes de la confirmación requerida.
- USDC y USDT solo se aceptan en las redes/token contracts configurados.
- No hay secretos en Git ni logs; RLS impide que un usuario lea los intentos de otro.
- Pruebas de sandbox, reconciliación, reembolsos/chargebacks y restauración de errores pasan.
- La rama sigue separada de `main`; no se despliega ni se fusiona automáticamente.

## Referencias oficiales consultadas

- Stripe — disponibilidad global: https://stripe.com/global
- Stripe — requisitos para cuenta en otro país: https://support.stripe.com/questions/requirements-to-open-a-stripe-account-in-another-country
- Stripe — disponibilidad de productos de gestión de fondos y stablecoins: https://stripe.com/money-management/availability
- PayPal — elegibilidad de servicios cripto en cuentas: https://securepayments.paypal.com/us/cshelp/article/can-i-purchase-crypto-with-my-business-account--help579
- Supabase — secretos de Edge Functions: https://supabase.com/docs/guides/functions/secrets
- Supabase — seguridad y webhooks de Edge Functions: https://supabase.com/docs/guides/functions/auth
