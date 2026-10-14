(() => {
  const $ = (s, root=document) => root.querySelector(s);
  const menu = $(".menu-toggle"), nav = $(".nav");
  if (menu && nav) menu.addEventListener("click", () => { const open=nav.classList.toggle("open"); menu.setAttribute("aria-expanded",String(open)); });
  const year=$("#year"); if(year) year.textContent=new Date().getFullYear();
  const cfg=window.UG_CONFIG;
  async function api(path, options={}) {
    if(!cfg?.supabaseUrl || !cfg?.supabaseKey) throw new Error("Falta configuración de Supabase.");
    const headers={apikey:cfg.supabaseKey,"Content-Type":"application/json",...(options.headers||{})};
    const token=localStorage.getItem("ug_access_token"); if(token) headers.Authorization="Bearer "+token;
    const response=await fetch(cfg.supabaseUrl+path,{...options,headers});
    const body=await response.json().catch(()=>null);
    if(!response.ok) throw new Error(body?.msg||body?.message||body?.error_description||body?.error||"La solicitud no pudo completarse.");
    return body;
  }
  window.UG={api, user:()=>JSON.parse(localStorage.getItem("ug_user")||"null"), token:()=>localStorage.getItem("ug_access_token"), requireAuth(){if(!this.token())location.href="login.html";}, async signOut(){try{await api("/auth/v1/logout",{method:"POST"});}catch{}localStorage.removeItem("ug_access_token");localStorage.removeItem("ug_refresh_token");localStorage.removeItem("ug_user");location.href="index.html";}};
  document.querySelectorAll("[data-signout]").forEach(el=>el.addEventListener("click",()=>window.UG.signOut()));
  document.querySelectorAll("[data-user-email]").forEach(el=>el.textContent=window.UG.user()?.email||"Cuenta"));
})();