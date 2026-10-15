# Fase A — pagos directos a wallet con revisión manual

Estado: **preparación técnica; cobros reales desactivados**. Panamá es el país operativo indicado para planificar el onboarding y la revisión legal; no se asume que el negocio ya esté constituido o que tenga una cuenta comercial aprobada.

## Entregado en esta rama

- `wallet-payment.html`: página informativa en HTML/CSS/JS nativo, sin CDN, que explica el estado desactivado y los riesgos de enviar fondos.
- `supabase/migrations/20261015090000_manual_wallet_payment_ledger.sql`: registro privado de solicitudes de pago manuales, con RLS de lectura solo para el usuario propietario y sin permisos de escritura desde el navegador.
- La migración distingue membresías, servicios y productos digitales, y registra activo, red, dirección de destino, importe esperado, vencimiento, hash comunicado y hash verificado.
- Se mantiene `main` intacta. La migración no se ha aplicado a Supabase y no hay despliegue.

## Qué NO está habilitado

- No se publican direcciones de wallet.
- No se crean órdenes ni se acepta dinero desde el sitio.
- No hay verificación automática on-chain, monitor de RPC, indexador, webhook, conversión fiat/stablecoin ni reembolso automatizado.
- No se activan membresías ni se marca un servicio como pagado.
- No hay checkout de tarjeta ni PayPal.
- No se permite que un vendedor publique una dirección de pago como si estuviera verificada por Universo Geek.

## Flujo manual previsto antes de producción

1. El administrador verifica y registra las direcciones oficiales de recepción y sus redes por un canal independiente.
2. Se define el token exacto por red, incluyendo contrato de token o mint cuando corresponda; no basta el símbolo USDC/USDT.
3. El backend crea una solicitud con importe calculado de forma confiable, red, token, dirección, vencimiento e identificador idempotente.
4. El usuario paga desde su wallet y puede presentar el hash para facilitar la revisión. El hash proporcionado por el usuario no se considera prueba suficiente.
5. Un operador autorizado verifica en un explorador/RPC independiente la red, token/contrato, dirección receptora, importe, estado final y confirmaciones. Debe comprobarse que la transacción no se haya contabilizado previamente.
6. La decisión se registra con actor, fecha y motivo. Solo el backend actualiza el pedido/membresía en una transacción atómica tras la revisión.
7. Para servicios entre miembros, no se inicia la cobranza hasta definir claramente si el vendedor recibe directamente, cómo se calcula la comisión, qué ocurre con una disputa y quién es responsable de los reembolsos.

## Riesgos y límites

- Las transferencias en blockchain generalmente son irreversibles; una dirección o red equivocada puede causar pérdida permanente.
- Ethereum y BNB Smart Chain son redes distintas aunque sus direcciones EVM tengan formato similar. Solana utiliza direcciones y formato de token diferentes.
- USDC/USDT pueden tener versiones oficiales, bridged o contratos distintos. Configurar y validar la lista exacta antes de aceptar pagos.
- El pago directo no elimina las sanciones, las restricciones territoriales, los requisitos fiscales ni posibles obligaciones de servicios de activos virtuales. Antes de lanzar desde Panamá, confirmar el modelo comercial y el tratamiento de pagos de terceros con asesoría local.
- No guardar claves privadas, frases semilla ni credenciales de RPC/proveedores en frontend, SQL versionado, tablas accesibles por clientes o logs.
- La tabla añadida no tiene política de escritura para navegador. Las futuras operaciones de escritura deben pasar por una Edge Function o procedimiento de backend con autenticación/autorización, validación y auditoría. No otorgar escritura directa a usuarios para facilitar una prueba.
- No usar cuentas de terceros, falsear residencia o identidad ni usar la estructura para evadir sanciones o restricciones de un proveedor.

## Pruebas necesarias antes de continuar

- Aplicar primero en un proyecto Supabase de desarrollo después de revisar las tablas existentes y ejecutar asesores de seguridad.
- Probar RLS con dos usuarios: cada uno debe leer únicamente sus propios registros; ambos deben fallar al insertar, actualizar, confirmar o borrar desde el cliente.
- Probar restricciones de activo/red/estado, idempotencia, hashes duplicados, importes inválidos y confirmación sin hash verificado.
- Añadir un procedimiento administrativo/backend seguro para crear y revisar solicitudes, con autorización por rol confiable y registro de auditoría.
- Ejecutar pruebas de extremo a extremo en testnet o con una transacción controlada de bajo importe, nunca mediante datos simulados marcados como pagados.
- Mantener la fase desactivada hasta completar onboarding, revisión legal, direcciones verificadas, procedimiento de reembolso y controles de seguridad.

## Criterio de salida

La Fase A se considerará lista para una beta limitada solo cuando exista una wallet de recepción verificada, un flujo backend de revisión auditado, pruebas RLS aprobadas, procedimiento de incidencias y confirmación de que el uso es legal y permitido para la operación en Panamá y los países atendidos.
