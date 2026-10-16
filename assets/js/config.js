/**
 * UNIVERSO GEEK — configuración pública del cliente.
 *
 * Este archivo puede estar versionado porque contiene únicamente la URL del
 * proyecto y una clave publishable de Supabase. La seguridad depende de RLS,
 * grants y funciones de backend bien configuradas.
 *
 * NUNCA añadir aquí:
 * - service_role / secret keys
 * - contraseñas, claves privadas o tokens de QvaPay
 * - secretos de webhooks o credenciales administrativas
 *
 * Para cambiar de proyecto, sustituye ambos valores por los del proyecto
 * correcto y prueba Auth/RLS en un entorno de desarrollo antes de continuar.
 */
window.UG_CONFIG = {
  // URL pública del proyecto Supabase.
  supabaseUrl: "https://khadcbgzziuwaxwptftw.supabase.co",

  // Clave publishable: se envía en peticiones del navegador.
  supabaseKey: "sb_publishable_ozK5Av8rJisppopqle6BGA_18ZKKEaV",

  // URL canónica del sitio. No usar localhost para enlaces de correo.
  // Esta URL solo será válida cuando exista un despliegue de producción.
  siteUrl: "https://universogeek.pages.dev"
};
