/**
 * UNIVERSO GEEK — asistente local de ayuda y buzón de sugerencias.
 *
 * No usa IA ni servicios externos: responde con una pequeña base de preguntas
 * frecuentes que podemos editar aquí. Si no reconoce una pregunta, lo dice con
 * claridad y ofrece enviar comentarios al equipo.
 *
 * La interfaz usa textContent para evitar interpretar mensajes como HTML.
 * Los comentarios se guardan en Supabase; RLS valida el usuario en el servidor.
 */
(() => {
  "use strict";

  const FAQ = [
    {keys:["registr","crear cuenta","abrir cuenta","inscrib","iniciar sesion","iniciar sesión","login","contraseña","contrasena","recuperar"],title:"Cuenta y acceso",answer:"Abre «Entrar» para crear una cuenta o iniciar sesión. Si olvidaste tu contraseña, usa la opción de recuperación de esa página. Si el correo de confirmación está activado, revisa también spam."},
    {keys:["servicio","marketplace","publicar","ilustr","diseñ","disen","edición","edicion","contratar","vendedor","comprador"],title:"Servicios del marketplace",answer:"En «Servicios» puedes explorar publicaciones aprobadas. Para publicar o solicitar un servicio, inicia sesión. Las publicaciones pueden necesitar moderación. Confirma el alcance y los detalles con la otra persona antes de comprometerte; el flujo de pagos del marketplace todavía no procesa pagos."},
    {keys:["membres","planes","geek","creator","pro","suscrip"],title:"Membresías",answer:"Consulta los planes en «Membresías». El checkout está desactivado mientras se completa la integración comercial de pagos. No envíes criptomonedas a direcciones compartidas en chats ni a direcciones de prueba."},
    {keys:["qvapay","pago","pagar","cripto","bitcoin","btc","ethereum","eth","solana","sol","bnb","factura","transaccion","transacción"],title:"Pagos",answer:"Los pagos reales están desactivados. Universo Geek está esperando la confirmación de la cuenta comercial de QvaPay; todavía no debes enviar fondos ni interpretar esta conversación como confirmación de un pago."},
    {keys:["moderador","moderación","moderacion","reportar","denunciar","contenido","abuso","fraude"],title:"Moderación y reportes",answer:"Las publicaciones del marketplace se revisan antes de aparecer. Si detectas contenido problemático, envía un comentario desde este asistente e indica la página y qué ocurrió. No incluyas contraseñas, documentos de identidad ni datos bancarios."},
    {keys:["privacidad","datos","información personal","informacion personal","cookies"],title:"Privacidad y cookies",answer:"Puedes consultar las páginas «Privacidad» y «Cookies» desde el pie del sitio. La documentación legal aún debe revisarse antes del lanzamiento. No compartas datos sensibles en el formulario de comentarios."},
    {keys:["contacto","ayuda","soporte","feedback","comentario","sugerencia","idea","mejorar","problema","error","bug"],title:"Enviar feedback",answer:"Puedes enviar una sugerencia, informar de un error o valorar tu experiencia con el formulario de este asistente. Incluye qué intentabas hacer, qué ocurrió y, si es posible, los pasos para reproducirlo. No es necesario dejar tu correo."},
    {keys:["telefono","teléfono","movil","móvil","celular","cuba","cdn","internet"],title:"Acceso y compatibilidad",answer:"El proyecto está construido con HTML, CSS y JavaScript nativo y busca evitar CDN externos. Aun así, algunas funciones requieren conexión a Supabase. Si algo no funciona en tu dispositivo o conexión, indícalo en el feedback."}
  ];

  const norm = value => String(value || "").toLocaleLowerCase("es").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^\p{L}\p{N}\s]/gu, " ").replace(/\s+/g, " ").trim();
  const score = (text, keys) => keys.reduce((n,key) => n + (text.includes(norm(key)) ? Math.max(1,norm(key).split(" ").length) : 0), 0);

  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function start() {
    if (document.querySelector("[data-ug-helpbot]")) return;

    const root = el("section", "ug-helpbot");
    root.dataset.ugHelpbot = "true";
    const toggle = el("button", "ug-helpbot__toggle", "💬 Ayuda y feedback");
    toggle.type = "button";
    toggle.setAttribute("aria-expanded", "false");
    toggle.setAttribute("aria-controls", "ug-helpbot-panel");

    const panel = el("div", "ug-helpbot__panel");
    panel.id = "ug-helpbot-panel";
    panel.hidden = true;
    const header = el("div", "ug-helpbot__header");
    const heading = el("div");
    heading.append(el("strong", "", "Asistente Universo Geek"), el("small", "", "Respuestas automáticas · puedes enviarnos sugerencias"));
    const close = el("button", "ug-helpbot__close", "Cerrar");
    close.type = "button";
    close.setAttribute("aria-label", "Cerrar asistente");
    header.append(heading, close);

    const messages = el("div", "ug-helpbot__messages");
    messages.setAttribute("role", "log");
    messages.setAttribute("aria-live", "polite");
    messages.append(el("p", "ug-helpbot__bubble ug-helpbot__bubble--bot", "¡Hola! Puedo ayudarte con cuentas, servicios, membresías, pagos y privacidad. También puedes dejar feedback abajo. Soy un asistente de respuestas frecuentes, no una persona."));
    const quick = el("div", "ug-helpbot__quick");
    ["¿Cómo creo una cuenta?","¿Cómo publico un servicio?","¿Se pueden realizar pagos?","Enviar una sugerencia"].forEach(label => {
      const b = el("button", "", label); b.type = "button";
      b.addEventListener("click", () => label === "Enviar una sugerencia" ? (feedback.scrollIntoView({behavior:"smooth",block:"start"}),message.focus()) : ask(label));
      quick.append(b);
    });

    const chatForm = el("form", "ug-helpbot__ask");
    const question = el("input");
    question.type = "text"; question.maxLength = 300; question.required = true;
    question.placeholder = "Escribe tu duda…"; question.setAttribute("aria-label","Escribe tu pregunta");
    const askButton = el("button", "button primary", "Preguntar"); askButton.type = "submit";
    chatForm.append(question,askButton);

    const feedback = el("form", "ug-helpbot__feedback");
    feedback.append(el("h3","","¿Cómo podemos mejorar?"),el("p","muted","Cuéntanos qué no funcionó o qué te gustaría ver. No incluyas contraseñas ni información sensible."));
    const categoryLabel=el("label","","Tipo de comentario");
    const category=document.createElement("select"); category.name="category";
    [["suggestion","Sugerencia"],["bug","Error o problema"],["question","Pregunta sin respuesta"],["content","Contenido"],["accessibility","Accesibilidad"],["other","Otro"]].forEach(([v,t])=>{const o=el("option","",t);o.value=v;category.append(o);});
    categoryLabel.append(category);
    const ratingLabel=el("label","","Valoración (opcional)");
    const rating=document.createElement("select"); rating.name="rating";
    [["","Sin valoración"],["5","5 — Excelente"],["4","4 — Bien"],["3","3 — Regular"],["2","2 — Malo"],["1","1 — Muy malo"]].forEach(([v,t])=>{const o=el("option","",t);o.value=v;rating.append(o);});
    ratingLabel.append(rating);
    const messageLabel=el("label","","Tu comentario");
    const message=document.createElement("textarea"); message.name="message"; message.required=true; message.minLength=5; message.maxLength=2000; message.rows=4; message.placeholder="¿Qué intentabas hacer? ¿Qué deberíamos mejorar?";
    messageLabel.append(message);
    const emailLabel=el("label","","Correo de contacto (opcional)");
    const email=document.createElement("input"); email.name="email"; email.type="email"; email.maxLength=254; email.autocomplete="email"; email.placeholder="tu@correo.com";
    emailLabel.append(email);
    // Campo trampa sencillo para bots de spam; no se muestra a usuarios normales.
    const honey=el("div","ug-helpbot__honeypot");
    const honeyLabel=el("label","","Dejar vacío"); const honeyInput=el("input"); honeyInput.name="website"; honeyInput.tabIndex=-1; honeyInput.autocomplete="off"; honeyLabel.append(honeyInput); honey.append(honeyLabel);
    const send=el("button","button primary","Enviar comentario"); send.type="submit";
    const feedbackStatus=el("p","ug-helpbot__status"); feedbackStatus.setAttribute("aria-live","polite");
    feedback.append(categoryLabel,ratingLabel,messageLabel,emailLabel,honey,send,feedbackStatus);

    panel.append(header,messages,quick,chatForm,feedback);
    root.append(toggle,panel);
    document.body.append(root);

    function open(opened) {
      panel.hidden = !opened;
      toggle.setAttribute("aria-expanded",String(opened));
      if (opened) question.focus();
    }
    toggle.addEventListener("click",()=>open(panel.hidden));
    close.addEventListener("click",()=>{open(false);toggle.focus();});

    function say(text,kind="bot") {
      const p=el("p","ug-helpbot__bubble "+(kind==="user"?"ug-helpbot__bubble--user":"ug-helpbot__bubble--bot"),text);
      messages.append(p);
      messages.scrollTop=messages.scrollHeight;
    }
    function answer(text) {
      const clean=norm(text);
      if (!clean) return "Escribe una pregunta para que pueda buscar una respuesta.";
      const ranked=FAQ.map(item=>({item,points:score(clean,item.keys)})).sort((a,b)=>b.points-a.points);
      if (!ranked[0] || ranked[0].points===0) return "No tengo una respuesta fiable para esa pregunta todavía. Prueba con «cuenta», «servicios», «membresías», «pagos» o envíanos la duda mediante el formulario de feedback.";
      return ranked[0].item.answer;
    }
    function ask(text) {
      say(text,"user");
      say(answer(text));
    }
    chatForm.addEventListener("submit",event=>{
      event.preventDefault();
      const value=question.value.trim();
      if(!value)return;
      ask(value);question.value="";
    });

    feedback.addEventListener("submit",async event=>{
      event.preventDefault();
      feedbackStatus.textContent="";
      if(honeyInput.value.trim()) return;
      const text=message.value.trim();
      if(text.length<5 || text.length>2000){feedbackStatus.textContent="Escribe entre 5 y 2000 caracteres.";return;}
      const cfg=window.UG_CONFIG;
      if(!cfg?.supabaseUrl || !cfg?.supabaseKey){feedbackStatus.textContent="El envío no está disponible por un problema de configuración.";return;}
      send.disabled=true; send.textContent="Enviando…";
      try {
        const user=window.UG?.user?.();
        const payload={
          user_id:user?.id || null,
          category:category.value,
          rating:rating.value ? Number(rating.value) : null,
          message:text,
          contact_email:email.value.trim() || null,
          page_path:location.pathname.slice(0,300),
          status:"new"
        };
        await window.UG.api("/rest/v1/site_feedback",{method:"POST",headers:{"Prefer":"return=minimal"},body:JSON.stringify(payload)});
        feedbackStatus.textContent="¡Gracias! Tu comentario quedó registrado para revisión.";
        feedback.reset();
        say("Gracias por compartir tu feedback. El equipo podrá revisarlo para priorizar mejoras.");
      } catch(error) {
        feedbackStatus.textContent="No se pudo enviar ahora. Comprueba la conexión e inténtalo de nuevo.";
      } finally {
        send.disabled=false; send.textContent="Enviar comentario";
      }
    });
  }

  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",start,{once:true});
  else start();
})();
