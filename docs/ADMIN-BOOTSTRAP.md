# Bootstrap del administrador en un entorno nuevo

Este procedimiento es solo para el propietario del proyecto, desde el SQL Editor de Supabase autenticado como administrador de base de datos. No es necesario ejecutarlo en el proyecto existente si el perfil administrador ya está configurado.

1. Crea/inicia la cuenta propietaria en **Authentication → Users**.
2. Copia el UUID del usuario propietario. Confirma que el perfil correspondiente existe en `public.profiles`.
3. Sustituye el UUID de ejemplo en el bloque siguiente y ejecútalo una sola vez desde el SQL Editor. No compartas el UUID públicamente.

```sql
do $$
declare
  owner_user_id uuid := 'REEMPLAZAR-POR-UUID-DE-AUTH-USER';
begin
  alter table public.profiles disable trigger protect_profile_role;

  update public.profiles
     set role = 'admin',
         display_name = case
           when coalesce(trim(display_name), '') = ''
           then 'Administrador Universo Geek'
           else display_name
         end
   where id = owner_user_id;

  if not found then
    raise exception 'No existe un perfil para el UUID indicado; no se ha asignado el rol.';
  end if;

  alter table public.profiles enable trigger protect_profile_role;
end
$$;
```

Si el bloque falla, la transacción del editor debe revertirse y el trigger debe seguir habilitado. Después, verifica el rol del propietario:

```sql
select id, display_name, role
from public.profiles
where id = 'REEMPLAZAR-POR-UUID-DE-AUTH-USER'::uuid;
```

Debe devolver `role = admin`. No uses esta técnica para ascender usuarios normales; los cambios de rol cotidianos deben pasar por las funciones administrativas protegidas.

## Por qué la migración de bootstrap está saneada

La base original aplicó un bootstrap usando el correo específico del propietario. Para no guardar datos personales en el repositorio, el archivo histórico correspondiente se conserva como marcador sin ejecutar cambios. En entornos nuevos, sigue el procedimiento manual de esta guía.
