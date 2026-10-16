/**
 * UNIVERSO GEEK — configuración pública del cliente.
 *
 * RELEASE CANDIDATE: esta rama usa exclusivamente el proyecto Supabase de pruebas.
 * Nunca fusionar este archivo en main ni usarlo en producción.
 * No copiar esta configuración a main ni usarla en producción.
 *
 * Nunca incluir aquí service_role/secret keys, contraseñas, tokens privados
 * ni secretos de webhooks o credenciales de QvaPay.
 */
window.UG_CONFIG = {
  // Proyecto Supabase de PRUEBAS: tvjglznjntegujfczljp.
  supabaseUrl: "https://tvjglznjntegujfczljp.supabase.co",

  // Clave publishable del mismo proyecto de pruebas.
  supabaseKey: "sb_publishable_CHejg8q9HPgthI1V_7Qjaw_mzxCh_L4",

  // URL estable de producción para enlaces generados en localhost.
  // En Cloudflare Pages, login.html conserva el origen de la vista previa.
  // Actualizar solo cuando se autorice publicar producción.
  siteUrl: "https://universogeek.pages.dev"
};
