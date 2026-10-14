/**
 * UNIVERSO GEEK — funciones compartidas del navegador.
 * Mantén aquí solo comportamientos reutilizables; el código propio de cada
 * pantalla debe vivir en assets/js/pages/<pantalla>.js.
 *
 * Seguridad: Supabase/RLS es la autoridad final. Nunca pongas aquí service_role,
 * contraseñas ni secretos de proveedores o webhooks.
 */
(() => {
  // Atajo local para encontrar elementos de la página.\n  const $ = (s, root=document) => root.querySelector(s);
  // Navegación móvil: abre o cierra el menú y actualiza el estado accesible.\n  const menu = $(".menu-toggle"), nav = $(".nav");
  if (menu && nav) menu.addEventListener("click", () => {
    const open=nav.classList.toggle("open");
    menu.setAttribute("aria-expanded",String(open));
  });
  const year=$("#year");
  if(year) year.textContent=new Date().getFullYear();
  // config.js contiene la URL y la clave publishable; no contiene secretos.\n  const cfg=window.UG_CONFIG;
  let refreshInFlight=null;
  // El usuario local solo ayuda a representar la interfaz; no prueba permisos.\n  const readUser=()=>{try{return JSON.parse(localStorage.getItem("ug_user")||"null");}catch{return null;}};
  /** Renueva la sesión expirada; comparte una única petición concurrente. */\n  async function refreshSession(){
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
  /** Cliente REST mínimo para Auth/PostgREST. Las políticas RLS mandan. */\n  async function request(path,options={},retry=true){
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
  // API pequeña y estable utilizada por las páginas del sitio.\n  window.UG={
    api:(path,options={})=>request(path,options),
    user:readUser,
    token:()=>localStorage.getItem("ug_access_token"),
    requireAuth(){if(!this.token()) location.href="login.html";},
    // Cierra sesión y limpia los tokens locales incluso si falla la petición remota.\n    async signOut(){
      try{await request("/auth/v1/logout",{method:"POST"},false);}catch{}
      localStorage.removeItem("ug_access_token");
      localStorage.removeItem("ug_refresh_token");
      localStorage.removeItem("ug_user");
      location.href="index.html";
    }
  };
  document.querySelectorAll("[data-signout]").forEach(el=>el.addEventListener("click",()=>window.UG.signOut()));
  document.querySelectorAll("[data-user-email]").forEach(el=>{el.textContent=window.UG.user()?.email||"Cuenta";});
})();