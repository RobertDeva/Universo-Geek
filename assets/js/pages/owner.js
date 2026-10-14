/* Centro del propietario: la autorización real la impone Supabase, no el HTML. */
(() => {
 const $=id=>document.getElementById(id), status=$("owner-status"), content=$("owner-content"), denied=$("owner-denied");
 const fmt=v=>new Intl.NumberFormat("es").format(Number(v||0));
 const usd=v=>new Intl.NumberFormat("en-US",{style:"currency",currency:"USD"}).format(Number(v||0));
 async function load(){
  try{
   if(!window.UG||!UG.token()){location.href="login.html";return;}
   status.textContent="Verificando permisos privados…";
   const result=await UG.api("/rest/v1/rpc/owner_dashboard_summary",{method:"POST",body:JSON.stringify({})});
   const d=Array.isArray(result)?result[0]:result;
   if(!d||d.authorized!==true)throw new Error("Acceso no autorizado.");
   const grid=document.createElement("section");grid.className="owner-grid";grid.id="owner-metrics";
   const items=[["Membresías cobradas (USD)",usd(d.membership_revenue_usd),"Órdenes pagadas: "+fmt(d.paid_membership_orders)],["Productos digitales cobrados (USD)",usd(d.digital_revenue_usd),"Compras pagadas: "+fmt(d.paid_digital_purchases)],["Membresías activas",fmt(d.active_memberships),"Registros activos"],["Servicios aprobados",fmt(d.published_services),"No equivale a ingresos"],["Pedidos de servicios",fmt(d.service_orders),"No equivale a dinero cobrado"],["Clics de afiliados",fmt(d.affiliate_clicks),"No equivale a comisiones"]];
   for(const [title,value,note] of items){const card=document.createElement("article");card.className="owner-card";const h=document.createElement("h2");h.textContent=title;const v=document.createElement("p");v.className="owner-metric";v.textContent=value;const n=document.createElement("p");n.className="owner-tag";n.textContent=note;card.append(h,v,n);grid.append(card);}
   const old=document.getElementById("owner-metrics");if(old)old.replaceWith(grid);else content.prepend(grid);
   content.hidden=false;denied.hidden=true;status.textContent="Acceso autorizado. Resumen agregado actualizado desde Supabase.";
  }catch(e){content.hidden=true;denied.hidden=false;status.textContent=e?.message||"No se pudo verificar el acceso.";}
 }
 $("owner-signout")?.addEventListener("click",async()=>{try{await UG.logout();}catch{}location.href="login.html";});
 load();
})();