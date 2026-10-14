# Guía para editar Universo Geek sin depender de un desarrollador

Esta guía está escrita para que el propietario pueda hacer cambios pequeños desde GitHub, incluso desde un teléfono. El proyecto usa HTML, CSS y JavaScript nativo: no necesita npm, compilación ni CDN.

## 1. Dónde editar cada cosa

| Si quieres cambiar… | Archivo recomendado |
|---|---|
| Portada, textos, botones y secciones | `index.html` |
| Colores, tipografía, espacios y diseño adaptable | `assets/css/style.css` |
| URL de Supabase y clave publicable | `assets/js/config.js` |
| Sesión, peticiones REST y menú común | `assets/js/app.js` |
| Registro, inicio de sesión y recuperación | `login.html` |
| Catálogo y publicación de servicios | `services.html` |
| Pedidos del comprador/vendedor | `dashboard.html` |
| Moderación de servicios y afiliados | `admin.html` |
| Planes y estado de pagos | `membership.html`, `payment-result.html` |
| Textos legales | `privacy.html`, `cookies.html` |
| Cambios de esquema y políticas de base de datos | Nuevo archivo dentro de `supabase/migrations/` |
| Instrucciones y estado técnico | `README.md`, `docs/` |

### Estructura recomendada para crecer

La versión actual conserva scripts específicos dentro de algunas páginas HTML para reducir el riesgo de una refactorización grande sin pruebas de navegador. Para las siguientes mejoras, migra gradualmente la lógica de cada página a archivos separados:

```text
assets/
  css/
    style.css                 # Variables visuales y componentes compartidos
  js/
    config.js                 # Solo configuración pública
    app.js                    # Sesión, API y comportamiento global
    pages/
      login.js                # Solo autenticación de la página login.html
      services.js             # Solo catálogo/publicación de servicios
      dashboard.js            # Solo pedidos del usuario
      admin.js                # Solo colas de moderación
supabase/
  migrations/                 # Cambios SQL versionados e inmutables
docs/
  GUIA-CODIGO-HUMANO.md       # Esta guía
  ESTADO-DE-IMPLEMENTACION.md # Qué funciona y qué falta
```

No muevas todos los scripts de una vez. Extrae una página, verifica que funciona y luego continúa con la siguiente.

## 2. Cómo se carga el código del navegador

En una página autenticada, el orden habitual es:

1. `assets/js/config.js`: define `window.UG_CONFIG`.
2. `assets/js/app.js`: crea `window.UG` con `UG.api()`, `UG.user()`, `UG.requireAuth()` y `UG.signOut()`.
3. El script específico de la página: utiliza esa API compartida.

Si cambias el nombre de un archivo o mueves un script, actualiza el `<script src="…">` correspondiente en la página HTML. No cargues `app.js` antes de `config.js`.

## 3. Cómo comentar el código

Los comentarios deben explicar **por qué existe una regla, qué espera una función y qué no debe modificarse**, no repetir cada línea.

Ejemplo recomendado:

```js
/**
 * Carga solo los servicios aprobados.
 * La política RLS del servidor también debe limitar los resultados.
 */
async function loadApprovedServices() {
  // Implementación de la consulta…
}
```

Para cada función nueva, documenta:
- Qué hace.
- Parámetros y valores esperados.
- Qué devuelve.
- Qué errores puede lanzar.
- Si requiere una sesión autenticada.

Usa nombres claros, una función por responsabilidad y evita funciones globales nuevas salvo que se compartan entre páginas.

## 4. Reglas de seguridad que no deben romperse

- La clave `sb_publishable_…` puede aparecer en el frontend. Una clave `service_role`, una clave secreta o un secreto de QvaPay **nunca** puede aparecer en HTML, CSS, JavaScript del navegador ni en un commit.
- Ocultar un botón no es control de acceso. Los permisos deben validarse en RLS o en una función de backend.
- No actives una membresía por la URL de retorno del navegador. El backend debe verificar el pago con el proveedor, la referencia y el importe, y procesar notificaciones de forma idempotente.
- No cambies directamente el estado de una orden financiera para “probar”.
- No uses datos personales reales en ejemplos, capturas, documentación o datos de prueba.
- Los textos de privacidad/cookies son borradores hasta completar la identidad y los datos de contacto del operador y revisar las obligaciones legales aplicables.

## 5. Cómo cambiar la base de datos

Nunca edites una migración que ya se aplicó a Supabase. Una migración aplicada es un registro histórico.

1. Crea un archivo nuevo con el prefijo de versión y un nombre descriptivo, por ejemplo `20261015090000_add_profile_bio.sql`.
2. Incluye una transacción cuando sea adecuada y comprueba qué sucede si la sentencia se ejecuta más de una vez.
3. Añade o actualiza políticas RLS junto con los permisos SQL; no confíes en la interfaz.
4. Prueba primero en un proyecto de desarrollo/copia de seguridad.
5. Aplica la migración mediante el flujo controlado de Supabase.
6. Verifica el resultado y registra en la documentación qué cambió y cómo revertirlo.
7. Guarda exactamente el SQL aplicado en `supabase/migrations/`.

No vuelvas a ejecutar todas las migraciones sobre la base de datos activa. El historial indica cuáles ya se aplicaron.

## 6. Flujo humano recomendado para cada cambio

1. **Define una tarea pequeña:** una página o un comportamiento cada vez.
2. **Crea una rama:** usa un nombre como `docs/update-navigation` o `fix/service-form-validation`.
3. **Edita desde GitHub:** usa el editor web y conserva los cambios que no formen parte de la tarea.
4. **Revisa el diff:** confirma que solo cambian los archivos esperados y que no hay claves ni datos privados.
5. **Prueba:** abre la página mediante un servidor local simple (por ejemplo, `python -m http.server 8080`); prueba móvil, escritorio, consola y errores de red.
6. **Para cambios de datos:** prueba RLS con cuentas separadas de usuario, moderador y administrador.
7. **Documenta:** actualiza el README o el estado de implementación si cambió el comportamiento.
8. **Integra solo después de revisar:** no publiques ni despliegues hasta tener autorización expresa.

### Lista de comprobación antes de guardar

- [ ] ¿El cambio es pequeño y tiene un objetivo claro?
- [ ] ¿Los nombres explican lo que hace el código?
- [ ] ¿El diseño funciona en móvil y escritorio?
- [ ] ¿Los mensajes de error son comprensibles?
- [ ] ¿Se siguen comprobando los permisos en el servidor?
- [ ] ¿He evitado secretos, datos personales y pagos reales?
- [ ] ¿He probado registro, sesión o pedidos si los he tocado?
- [ ] ¿He actualizado esta documentación si hace falta?

## 7. Límites actuales

La documentación y los comentarios facilitan la edición, pero no sustituyen las pruebas. Antes de publicar hay que ejecutar pruebas de navegador, probar RLS con varios roles y revisar la configuración de Auth. La integración comercial de QvaPay permanece desactivada hasta que se apruebe la cuenta y se valide el protocolo oficial.
