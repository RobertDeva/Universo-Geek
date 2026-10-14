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

  // Respuestas redactadas a partir de las páginas y los flujos actuales del repositorio.
  // No añadir afirmaciones hasta verificarlas en el código o en Supabase.
  const FAQ = [
    {keys:["cuenta","crear cuenta","registrarme","registro","iniciar sesion","entrar","login","contrasena","recuperar contraseña"],title:"Cuenta",answer:"La página Entrar permite iniciar sesión, crear una cuenta con correo y contraseña y solicitar la recuperación de contraseña. Si la confirmación por correo está activada, revisa también la bandeja de spam."},
    {keys:["servicio","servicios","servicios aprobados","publicar servicio","publicar un servicio","solicitar servicio","marketplace","contratar un servicio"],title:"Servicios",answer:"La página Servicios muestra los servicios aprobados y permite iniciar sesión para publicar o enviar una solicitud. La solicitud no cobra ni reserva dinero; el marketplace no procesa pagos en esta versión."},
    {keys:["membresias","planes","plan geek","plan creator","plan otaku pro","otaku pro"],title:"Membresías",answer:"La página Membresías muestra las opciones Geek, Creator y Otaku Pro. Son informativas en esta versión: el checkout está desactivado y no se puede pagar ni activar una membresía desde el sitio."},
    {keys:["qvapay","pagos","pagar","criptomonedas","bitcoin","btc","ethereum","eth","solana","bnb","checkout","transaccion"],title:"Pagos",answer:"Los pagos reales están desactivados. La integración comercial de QvaPay sigue en preparación y depende de la cuenta comercial y de la verificación del backend. No envíes dinero ni criptomonedas; el bot no puede confirmar pagos."},
    {keys:["feedback","sugerencia","enviar comentario","reportar error","problema","pregunta sin respuesta"],title:"Feedback",answer:"Puedes enviar una pregunta o sugerencia con el formulario de este asistente. El correo es opcional. Los comentarios quedan para revisión administrativa; no hay un plazo de respuesta prometido. No incluyas contraseñas, claves privadas ni datos bancarios."},
    {keys:["privacidad","cookies","terminos y condiciones","datos personales"],title:"Políticas",answer:"El sitio incluye páginas de Privacidad, Cookies y Términos y condiciones. Los propios documentos indican que deben revisarse antes del lanzamiento comercial."},
    {keys:["moderacion","moderador","administrador","anuncio pendiente"],title:"Moderación",answer:"El panel de moderación incluye colas de servicios y anuncios pendientes. La bandeja de feedback está reservada al rol admin; los moderadores no tienen acceso a esa bandeja por defecto."},
    {keys:["que es universo geek","que ofrece universo geek","sobre universo geek","sobre el sitio","comunidad gamer","comunidad de anime","comunidad de manga","comunidad de manhwa","latinoamerica","estados unidos"],title:"Sobre el sitio",answer:"Universo Geek es una plataforma en desarrollo para la comunidad gamer y fans del anime, manga y manhwa, con enfoque en Latinoamérica y Estados Unidos. La portada presenta la comunidad y el marketplace de servicios creativos."}
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
      const clean = norm(text);
      if (!clean) return "Escribe una pregunta sobre una función de Universo Geek.";
      const matches = FAQ.map(item => ({
        item,
        score: item.keys.reduce((n,key) => n + (((" " + clean + " ").includes(" " + norm(key) + " ")) ? Math.max(1,norm(key).split(" ").length) : 0), 0)
      })).filter(result => result.score > 0).sort((a,b) => b.score-a.score);
      if (!matches.length) return "No encuentro una respuesta confirmada para esa pregunta en la documentación actual del sitio. No voy a adivinar. Envíala como «Pregunta sin respuesta» mediante el formulario para que el equipo pueda revisarla.";
      if (matches.length > 1 && matches[0].score < matches[1].score + 2) return "Tu pregunta puede referirse a más de una función y no quiero darte información incorrecta. Reformúlala sobre un solo tema o envíala al equipo mediante el formulario.";
      return matches[0].item.answer;
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
          category:category.value,
          rating:rating.value ? Number(rating.value) : null,
          message:text,
          contact_email:email.value.trim() || null,
          page_path:location.pathname.slice(0,300),
          website:honeyInput.value
        };
        await window.UG.api("/functions/v1/submit-site-feedback",{method:"POST",body:JSON.stringify(payload)});
        feedbackStatus.textContent="Gracias. Tu comentario se ha enviado para revisión; no hay un plazo de respuesta prometido.";
        feedback.reset();
        say("Gracias por compartir tu feedback. El equipo podrá revisarlo para priorizar mejoras.");
      } catch(error) {
        feedbackStatus.textContent=error?.message==="rate_limited" ? "Has alcanzado el límite de envíos. Inténtalo más tarde." : "No se pudo enviar ahora. Comprueba la conexión e inténtalo de nuevo.";
      } finally {
        send.disabled=false; send.textContent="Enviar comentario";
      }
    });
  }

  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",start,{once:true});
  else start();
})();
