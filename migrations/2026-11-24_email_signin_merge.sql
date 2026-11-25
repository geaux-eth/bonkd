-- v69: email sign-in. A device that signs in to an existing email account first asks for a one-time
-- merge code (prep_merge, while still on its own anonymous account), then after the sign-in hands the
-- code to absorb_merge, which pours that device's waffles, purchases, progress and rewards into the
-- email account's profile. Same merge rules as use_move_code (rewards both had are paid once).

create or replace function public.prep_merge()
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare
  pid uuid; abc text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; b bytea := gen_random_bytes(10); code text := ''; i int;
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  if not exists (select 1 from public.waffle_board where id = pid) then
    return jsonb_build_object('ok', false, 'reason', 'empty');
  end if;
  for i in 0..9 loop code := code || substr(abc, 1 + get_byte(b, i) % length(abc), 1); end loop;
  update public.waffle_board set move_code = code, move_expires = now() + interval '15 minutes' where id = pid;
  return jsonb_build_object('ok', true, 'code', code);
end $$;

create or replace function public.absorb_merge(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  me uuid; src public.waffle_board; dst public.waffle_board; dup bigint;
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  me := public.bonkd_me();
  select * into src from public.waffle_board
   where move_code = upper(trim(coalesce(p_code, ''))) and move_expires > now() for update;
  if not found then return jsonb_build_object('ok', false, 'reason', 'bad_code'); end if;
  if src.id = me then return jsonb_build_object('ok', true); end if;
  select * into dst from public.waffle_board where id = me for update;
  if not found then
    insert into public.waffle_board (id, nick, pfp, waffles, best, runs, updated_at)
    values (me, null, src.pfp, 0, 0, 0, now()) returning * into dst;
  end if;
  select coalesce(sum(a.amount), 0) into dup from public.bonkd_rewards a
   where a.player = src.id and exists (select 1 from public.bonkd_rewards b where b.player = me and b.key = a.key);
  -- the device's handle is freed first, so the email profile can take it if it has none
  update public.waffle_board set nick = null, move_code = null, move_expires = null where id = src.id;
  update public.waffle_board
     set waffles = dst.waffles + src.waffles, best = greatest(dst.best, src.best), runs = dst.runs + src.runs,
         bought = coalesce(dst.bought,0) + coalesce(src.bought,0), spent = coalesce(dst.spent,0) + coalesce(src.spent,0),
         bonus = coalesce(dst.bonus,0) + coalesce(src.bonus,0) - dup,
         lives = coalesce(dst.lives,0) + coalesce(src.lives,0),
         owned = array(select distinct x from unnest(coalesce(dst.owned,'{}') || coalesce(src.owned,'{}')) x),
         nick = coalesce(dst.nick, src.nick), pfp = coalesce(dst.pfp, src.pfp),
         cleared_at = coalesce(dst.cleared_at, src.cleared_at),
         updated_at = now()
   where id = me returning * into dst;
  update public.waffle_runs set player = me where player = src.id;
  update public.level_progress lp
     set clears = lp.clears + d.clears, best_bonks = least(lp.best_bonks, d.best_bonks),
         first_clear = least(lp.first_clear, d.first_clear), bonkless_at = coalesce(lp.bonkless_at, d.bonkless_at)
    from public.level_progress d
   where lp.player = me and d.player = src.id and d.level = lp.level;
  update public.level_progress set player = me
   where player = src.id and level not in (select level from public.level_progress where player = me);
  update public.bonkd_rewards set player = me
   where player = src.id and key not in (select key from public.bonkd_rewards where player = me);
  update public.waffle_board set waffles = 0, best = 0, runs = 0, bought = 0, spent = 0, bonus = 0, lives = 0, owned = '{}' where id = src.id;
  -- any other device that was linked to the old profile now plays as the email profile too
  update public.profile_devices set profile = me where profile = src.id;
  insert into public.profile_devices (device, profile) values (src.id, me)
  on conflict (device) do update set profile = excluded.profile, linked_at = now();
  return jsonb_build_object('ok', true, 'nick', dst.nick, 'waffles', dst.waffles);
end $$;

revoke all on function public.prep_merge() from public, anon;
revoke all on function public.absorb_merge(text) from public, anon;
grant execute on function public.prep_merge() to authenticated;
grant execute on function public.absorb_merge(text) to authenticated;
