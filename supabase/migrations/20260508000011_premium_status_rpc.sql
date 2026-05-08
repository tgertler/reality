create or replace function public.fn_check_premium_status(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_premium boolean;
  v_premium_until timestamptz;
  v_is_service_role boolean := coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role';
begin
  if p_user_id is null then
    return false;
  end if;

  if not v_is_service_role and auth.uid() is distinct from p_user_id then
    raise exception 'not allowed';
  end if;

  select is_premium, premium_until
    into v_is_premium, v_premium_until
  from public.profiles
  where id = p_user_id;

  if coalesce(v_is_premium, false) = false then
    return false;
  end if;

  return v_premium_until is null or v_premium_until > now();
end;
$$;

revoke all on function public.fn_check_premium_status(uuid) from public;
grant execute on function public.fn_check_premium_status(uuid) to authenticated;
grant execute on function public.fn_check_premium_status(uuid) to service_role;

create or replace function public.fn_set_premium_status(
  p_user_id uuid,
  p_is_premium boolean,
  p_expires_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_service_role boolean := coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role';
begin
  if not v_is_service_role then
    raise exception 'not allowed';
  end if;

  update public.profiles
  set
    is_premium = coalesce(p_is_premium, false),
    premium_until = case
      when coalesce(p_is_premium, false) then p_expires_at
      else null
    end,
    updated_at = now()
  where id = p_user_id;
end;
$$;

revoke all on function public.fn_set_premium_status(uuid, boolean, timestamptz) from public;
grant execute on function public.fn_set_premium_status(uuid, boolean, timestamptz) to service_role;
