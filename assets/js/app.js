/**
 * UNIVERSO GEEK — funciones compartidas del navegador.
 * Mantén aquí solo comportamientos reutilizables; el código propio de cada
 * pantalla debe vivir en assets/js/pages/<pantalla>.js.
 *
 * Seguridad: Supabase/RLS es la autoridad final. Nunca pongas aquí service_role,
 * contraseñas ni secretos de proveedores o webhooks.
 */
(() => {
  // Atajo local para encontrar elementos de la página.
  const $ = (s, root=document) => root.querySelector(s);
  // Acceso rápido al contenido para teclado y lectores de pantalla.
  if (!$(".skip-link")) {
    const skip = document.createElement("a");
    skip.className = "skip-link";
    skip.href = "#main";
    skip.textContent = "Saltar al contenido";
    document.body.prepend(skip);
  }
  const main = $("main");
  if (main && !main.id) main.id = "main";

  // Preferencia de tema local: no requiere cookies ni servicios externos.
  const root = document.documentElement;
  const savedTheme = (() => { try { return localStorage.getItem("ug_theme"); } catch { return null; } })();
  const initialTheme = savedTheme === "light" || savedTheme === "dark"
    ? savedTheme
    : (window.matchMedia?.("(prefers-color-scheme: light)").matches ? "light" : "dark");
  root.dataset.theme = initialTheme;
  const header = $(".site-header"), nav = $(".nav");
  if (header && nav && !$(".theme-toggle")) {
    const themeButton = document.createElement("button");
    themeButton.type = "button";
    themeButton.className = "theme-toggle";
    themeButton.setAttribute("data-theme-toggle", "");
    themeButton.setAttribute("aria-pressed", String(initialTheme === "light"));
    themeButton.setAttribute("aria-label", "Cambiar tema de color");
    themeButton.textContent = initialTheme === "light" ? "🌙 Tema oscuro" : "☀️ Tema claro";
    nav.append(themeButton);
  }
  const updateThemeButton = () => {
    const button = $("[data-theme-toggle]");
    if (!button) return;
    const light = root.dataset.theme === "light";
    button.textContent = light ? "🌙 Tema oscuro" : "☀️ Tema claro";
    button.setAttribute("aria-pressed", String(light));
  };
  document.addEventListener("click", event => {
    const themeButton = event.target?.closest?.("[data-theme-toggle]");
    if (!themeButton) return;
    const next = root.dataset.theme === "light" ? "dark" : "light";
    root.dataset.theme = next;
    try { localStorage.setItem("ug_theme", next); } catch {}
    updateThemeButton();
  });

  // Navegación móvil: actualiza el estado accesible y permite cerrar con teclado.
  const menu = $(".menu-toggle");
  if (menu && nav) {
    const closeMenu = () => {
      nav.classList.remove("open");
      menu.setAttribute("aria-expanded", "false");
      menu.setAttribute("aria-label", "Abrir menú");
    };
    menu.addEventListener("click", () => {
      const open = nav.classList.toggle("open");
      menu.setAttribute("aria-expanded", String(open));
      menu.setAttribute("aria-label", open ? "Cerrar menú" : "Abrir menú");
    });
    nav.querySelectorAll("a").forEach(link => link.addEventListener("click", closeMenu));
    document.addEventListener("keydown", event => {
      if (event.key === "Escape") closeMenu();
    });
    document.addEventListener("click", event => {
      if (!nav.contains(event.target) && !menu.contains(event.target)) closeMenu();
    });
  }

  // Búsqueda local de secciones en la portada; no finge ser un buscador global.
  const sectionSearch = $("[data-section-search]");
  const searchableCards = Array.from(document.querySelectorAll("[data-search-card]"));
  const searchStatus = $("[data-search-status]");
  if (sectionSearch && searchableCards.length) {
    const runSearch = () => {
      const query = sectionSearch.value.trim().toLocaleLowerCase();
      let visible = 0;
      searchableCards.forEach(card => {
        const matches = !query || card.textContent.toLocaleLowerCase().includes(query);
        card.hidden = !matches;
        if (matches) visible++;
      });
      if (searchStatus) {
        searchStatus.textContent = query
          ? (visible ? visible + (visible === 1 ? " sección encontrada." : " secciones encontradas.") : "No encontramos secciones con ese término. Prueba con gaming, anime, servicios o membresías.")
          : "Busca por gaming, anime, servicios o membresías.";
      }
    };
    sectionSearch.addEventListener("input", runSearch);
    runSearch();
  }
  const year=$("#year");
  if(year) year.textContent=new Date().getFullYear();
  // config.js contiene la URL y la clave publishable; no contiene secretos.
  const cfg=window.UG_CONFIG;
  let refreshInFlight=null;
  // El usuario local solo ayuda a representar la interfaz; no prueba permisos.
  const readUser=()=>{try{return JSON.parse(localStorage.getItem("ug_user")||"null");}catch{return null;}};
  /** Renueva la sesión expirada; comparte una única petición concurrente. */
  async function refreshSession(){
    const refreshToken=localStorage.getItem("ug_refresh_token");
    if(!refreshToken || !cfg?.supabaseUrl || !cfg?.supabaseKey) return false;
    if(refreshInFlight) return refreshInFlight;
    refreshInFlight=(async()=>{
      try{
        const response=await fetch(cfg.supabaseUrl+"/auth/v1/token?grant_type=refresh_token",{
          method:"POST",
          headers:{apikey:cfg.supabaseKey,"Content-Type":"application/json"},
          body:JSON.stringify({refresh_token:refreshToken})
        });
        const data=await response.json().catch(()=>null);
        if(!response.ok || !data?.access_token) return false;
        localStorage.setItem("ug_access_token",data.access_token);
        if(data.refresh_token) localStorage.setItem("ug_refresh_token",data.refresh_token);
        if(data.user) localStorage.setItem("ug_user",JSON.stringify(data.user));
        return true;
      }catch{return false;}
      finally{refreshInFlight=null;}
    })();
    return refreshInFlight;
  }
  /** Cliente REST mínimo para Auth/PostgREST. Las políticas RLS mandan. */
  async function request(path,options={},retry=true){
    if(!cfg?.supabaseUrl || !cfg?.supabaseKey) throw new Error("Falta configuración de Supabase.");
    const headers={apikey:cfg.supabaseKey,"Content-Type":"application/json",...(options.headers||{})};
    const token=localStorage.getItem("ug_access_token");
    if(token) headers.Authorization="Bearer "+token;
    const response=await fetch(cfg.supabaseUrl+path,{...options,headers});
    if(response.status===401 && retry && !path.includes("/auth/v1/token") && await refreshSession()){
      return request(path,options,false);
    }
    const body=await response.json().catch(()=>null);
    if(!response.ok) throw new Error(body?.msg||body?.message||body?.error_description||body?.error||"La solicitud no pudo completarse.");
    return body;
  }
  // API pequeña y estable utilizada por las páginas del sitio.
  window.UG={
    api:(path,options={})=>request(path,options),
    user:readUser,
    token:()=>localStorage.getItem("ug_access_token"),
    requireAuth(){if(!this.token()) location.href="login.html";},
    // Cierra sesión y limpia los tokens locales incluso si falla la petición remota.
    async signOut(){
      try{await request("/auth/v1/logout",{method:"POST"},false);}catch{}
      localStorage.removeItem("ug_access_token");
      localStorage.removeItem("ug_refresh_token");
      localStorage.removeItem("ug_user");
      location.href="index.html";
    }
  };
  document.querySelectorAll("[data-signout]").forEach(el=>el.addEventListener("click",()=>window.UG.signOut()));
  document.querySelectorAll("[data-user-email]").forEach(el=>{el.textContent=window.UG.user()?.email||"Cuenta";});

  // Carga el asistente de ayuda en todas las páginas sin CDN ni dependencias externas.
  // El archivo del bot se mantiene separado para que pueda editarse de forma independiente.
  if (!document.querySelector('script[data-ug-helpbot-script]')) {
    const helpBotScript = document.createElement("script");
    helpBotScript.src = "assets/js/help-bot.js";
    helpBotScript.dataset.ugHelpbotScript = "true";
    helpBotScript.defer = true;
    document.head.append(helpBotScript);
  }
})();