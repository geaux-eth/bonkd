-- v67: per-level progress, single-level replays, once-only waffle rewards.
-- Applied to Supabase project jmiesqhrpcmrthrquqpq on 2026-10-31 as four migrations:
-- bonkd_progress_tables, bonkd_progress_functions, bonkd_wallet_includes_bonus_a,
-- bonkd_move_code_carries_progress, bonkd_bank_replay.
-- Wallet everywhere is now waffles + bought + bonus - spent. Rewards go to `bonus`
-- (spend-only: not on the leaderboard, not counted for MILLIONAIRE).

alter table public.waffle_board add column if not exists bonus bigint not null default 0;

create table if not exists public.level_progress (
  player uuid not null references public.waffle_board(id),
  level int not null check (level between 1 and 31),
  clears int not null default 0,
  best_bonks int not null default 99,
  first_clear timestamptz not null default now(),
  bonkless_at timestamptz,
  primary key (player, level)
);
alter table public.level_progress enable row level security;

create table if not exists public.bonkd_rewards (
  player uuid not null references public.waffle_board(id),
  key text not null,           -- bonkless:<level> | ultra:<setting> | badge:<id>
  amount bigint not null,
  at timestamptz not null default now(),
  primary key (player, key)
);
alter table public.bonkd_rewards enable row level security;

-- pays a reward once per key (internal only)
CREATE OR REPLACE FUNCTION public.bonkd_pay(p_player uuid, p_key text, p_amount bigint)
 RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
begin
  insert into public.bonkd_rewards (player, key, amount) values (p_player, p_key, p_amount)
  on conflict do nothing;
  if not found then return 0; end if;
  update public.waffle_board set bonus = bonus + p_amount, updated_at = now() where id = p_player;
  return p_amount;
end $function$;
revoke all on function public.bonkd_pay(uuid, text, bigint) from public, anon, authenticated;

-- a level was cleared (normal run or replay). First bonkless clear pays 100 x setting
-- (doorstep 31 = 1,000); all five of a setting bonkless pays 1,000 x setting.
CREATE OR REPLACE FUNCTION public.record_level(p_level integer, p_bonks integer, p_seconds integer)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
declare
  pid uuid; r public.waffle_board; setting int; paid bigint := 0; got jsonb := '[]'::jsonb; n bigint; maxlv int; all5 int;
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  if p_level is null or p_level < 1 or p_level > 31 then return jsonb_build_object('ok', false, 'reason', 'bad_level'); end if;
  if p_bonks is null or p_bonks < 0 or p_bonks > 99 then return jsonb_build_object('ok', false, 'reason', 'bad_bonks'); end if;
  if p_seconds is null or p_seconds < 8 then return jsonb_build_object('ok', false, 'reason', 'too_fast'); end if;
  insert into public.waffle_board (id) values (pid) on conflict (id) do nothing;
  select coalesce(max(level), 0) into maxlv from public.level_progress where player = pid;
  select * into r from public.waffle_board where id = pid;
  if p_level > greatest(maxlv, coalesce(r.best, 0)) + 1 then return jsonb_build_object('ok', false, 'reason', 'not_reached'); end if;
  insert into public.level_progress as lp (player, level, clears, best_bonks, bonkless_at)
  values (pid, p_level, 1, p_bonks, case when p_bonks = 0 then now() end)
  on conflict (player, level) do update
    set clears = lp.clears + 1, best_bonks = least(lp.best_bonks, excluded.best_bonks),
        bonkless_at = coalesce(lp.bonkless_at, excluded.bonkless_at);
  if p_bonks = 0 then
    setting := case when p_level = 31 then 7 else (p_level - 1) / 5 + 1 end;
    n := public.bonkd_pay(pid, 'bonkless:' || p_level, case when p_level = 31 then 1000 else 100 * setting end);
    if n > 0 then paid := paid + n; got := got || jsonb_build_object('key', 'bonkless', 'level', p_level, 'amount', n); end if;
    if p_level <= 30 then
      select count(*) into all5 from public.level_progress
       where player = pid and bonkless_at is not null and level between (setting - 1) * 5 + 1 and setting * 5;
      if all5 = 5 then
        n := public.bonkd_pay(pid, 'ultra:' || setting, 1000 * setting);
        if n > 0 then paid := paid + n; got := got || jsonb_build_object('key', 'ultra-bonkless', 'setting', setting, 'amount', n); end if;
      end if;
    end if;
  end if;
  select * into r from public.waffle_board where id = pid;
  return jsonb_build_object('ok', true, 'paid', paid, 'got', got, 'wallet', r.waffles + r.bought + r.bonus - r.spent);
end $function$;

-- badge rewards, paid once
CREATE OR REPLACE FUNCTION public.claim_badge(p_badge text)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
declare pid uuid; r public.waffle_board; amt bigint; n bigint := 0;
  prices jsonb := '{"connoisseur":5000,"streaker":5000,"explorer":2500,"grumblemax":10000,"millionaire":10000}';
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  if not (prices ? p_badge) then return jsonb_build_object('ok', false, 'reason', 'bad_badge'); end if;
  insert into public.waffle_board (id) values (pid) on conflict (id) do nothing;
  select * into r from public.waffle_board where id = pid;
  if p_badge = 'millionaire' and r.waffles < 1000000 then return jsonb_build_object('ok', false, 'reason', 'not_yet'); end if;
  if p_badge = 'grumblemax' and r.cleared_at is null then
    update public.waffle_board set cleared_at = now() where id = pid;
  end if;
  amt := (prices->>p_badge)::bigint;
  n := public.bonkd_pay(pid, 'badge:' || p_badge, amt);
  select * into r from public.waffle_board where id = pid;
  return jsonb_build_object('ok', true, 'paid', n, 'wallet', r.waffles + r.bought + r.bonus - r.spent);
end $function$;

CREATE OR REPLACE FUNCTION public.my_progress()
 RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object('level', level, 'clears', clears, 'best', best_bonks, 'bonkless', bonkless_at is not null) order by level), '[]'::jsonb)
    from public.level_progress where player = public.bonkd_me();
$function$;

-- banking waffles from a replay: level must already be reached; per-replay caps
CREATE OR REPLACE FUNCTION public.bank_replay(p_counts jsonb, p_level integer, p_seconds integer)
 RETURNS waffle_board LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
declare
  pid uuid;
  vals jsonb := '{"plain":5,"chicken":25,"report":100,"unicorn":250,"ring":1000,"refund":500,"tree":5000,"barrow":2000,"truck":10000,"lotto":25000}';
  k text; n int; total bigint := 0; plain_n int := 0; special_n int := 0; reached int;
  r public.waffle_board;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  pid := public.bonkd_me();
  if p_level is null or p_level < 1 or p_level > 31 then raise exception 'level out of range'; end if;
  if p_seconds is null or p_seconds < 0 or p_seconds > 3600 then raise exception 'time out of range'; end if;
  select greatest(coalesce(b.best, 0), coalesce((select max(level) from public.level_progress where player = pid), 0) + 1,
                  case when b.cleared_at is not null then 31 else 0 end)
    into reached from public.waffle_board b where b.id = pid;
  if coalesce(reached, 0) < p_level then raise exception 'level not reached'; end if;
  for k, n in select key, value::int from jsonb_each_text(coalesce(p_counts, '{}'::jsonb)) loop
    if not (vals ? k) or n < 0 or n > 400 then raise exception 'unknown waffle'; end if;
    total := total + n * (vals->>k)::int;
    if k = 'plain' then plain_n := n; else special_n := special_n + n; end if;
  end loop;
  if plain_n > 15 + p_seconds / 5 then raise exception 'too many waffles'; end if;
  if special_n > 6 + p_seconds / 30 then raise exception 'too many special waffles'; end if;
  if coalesce((p_counts->>'lotto')::int, 0) > 1 then raise exception 'too lucky'; end if;
  if coalesce((p_counts->>'truck')::int, 0) > 1 then raise exception 'too lucky'; end if;
  update public.waffle_board set waffles = waffles + total, updated_at = now() where id = pid returning * into r;
  return r;
end;
$function$;

grant execute on function public.record_level(int, int, int), public.claim_badge(text), public.my_progress(),
  public.bank_replay(jsonb, int, int) to anon, authenticated;

-- Also changed (see live definitions): buy_item, buy_life and my_profile use
-- waffles + bought + bonus - spent (my_profile also returns 'bonus');
-- use_move_code merges bonus (minus rewards both profiles were paid), and moves/merges
-- level_progress and bonkd_rewards with UPDATEs only.
