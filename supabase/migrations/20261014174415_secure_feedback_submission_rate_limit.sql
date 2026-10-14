create or replace function public.submit_site_feedback(
  p_ip_hash text,
  p_user_id uuid,
  p_category text,
  p_rating smallint,
  p_message text,
  p_contact_email text,
  p_page_path text
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  n integer;
begin
  if p_ip_hash is null or p_ip_hash !~ '^[0-9a-f]{64}$'
    or p_category not in ('question','bug','suggestion','content','accessibility','other')
    or (p_rating is not null and p_rating not between 1 and 5)
    or p_message is null or char_length(btrim(p_message)) not between 5 and 2000
    or (p_contact_email is not null and char_length(p_contact_email)>254)
    or (p_page_path is not null and (char_length(p_page_path)>300 or left(p_page_path,1)<>'/')) then
    return jsonb_build_object('ok',false,'reason','invalid_request');
  end if;
  insert into public.site_feedback_rate_limits(ip_hash,window_started_at,request_count)
  values(p_ip_hash,now(),1)
  on conflict(ip_hash) do update set
    window_started_at=case when public.site_feedback_rate_limits.window_started_at < now()-interval '1 hour' then now() else public.site_feedback_rate_limits.window_started_at end,
    request_count=case when public.site_feedback_rate_limits.window_started_at < now()-interval '1 hour' then 1 else public.site_feedback_rate_limits.request_count+1 end
  returning request_count into n;
  if n>5 then return jsonb_build_object('ok',false,'reason','rate_limited'); end if;
  insert into public.site_feedback(user_id,category,rating,message,contact_email,page_path,status)
  values(p_user_id,p_category,p_rating,btrim(p_message),nullif(btrim(p_contact_email),''),p_page_path,'new');
  delete from public.site_feedback_rate_limits where window_started_at < now()-interval '30 days';
  return jsonb_build_object('ok',true);
end;
$$;
revoke all on function public.submit_site_feedback(text,uuid,text,smallint,text,text,text) from public, anon, authenticated;
grant execute on function public.submit_site_feedback(text,uuid,text,smallint,text,text,text) to service_role;
revoke insert on public.site_feedback from anon, authenticated;
drop policy if exists "public can submit site feedback" on public.site_feedback;

