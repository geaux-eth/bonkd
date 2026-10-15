-- Bonkd Waffle Board
-- Run this whole file in Supabase > SQL Editor. It is safe to run again.

create table if not exists public.waffle_board (
  id uuid primary key references auth.users(id) on delete cascade,
  nick text check (char_length(nick) <= 14),
  waffles bigint not null default 0 check (waffles >= 0),
  best int not null default 0,
  runs int not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.waffle_board add column if not exists last_run_at timestamptz;
alter table public.waffle_board enable row level security;

-- Everyone can read the board. Nobody writes to it directly:
-- all writes go through the two checked functions below.
drop policy if exists "Anyone can read the board" on public.waffle_board;
drop policy if exists "Players add their own row" on public.waffle_board;
drop policy if exists "Players update their own row" on public.waffle_board;
create policy "Anyone can read the board" on public.waffle_board for select using (true);
revoke insert, update, delete, truncate, references, trigger on public.waffle_board from anon, authenticated;

-- A finished run. The game sends how many of each waffle type it collected,
-- the level reached, and seconds of play. The database works out the value
-- itself and rejects runs that are not possible in the game.
create or replace function public.submit_run(p_counts jsonb, p_level int, p_seconds int)
returns public.waffle_board
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  vals jsonb := '{"plain":1,"chicken":5,"report":7,"unicorn":10,"ring":25,"refund":50,"tree":100,"barrow":150,"truck":333,"lotto":2000}';
  k text;
  n int;
  total bigint := 0;
  plain_n int := 0;
  special_n int := 0;
  cleared int;
  r public.waffle_board;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if p_level is null or p_level < 1 or p_level > 500 then raise exception 'level out of range'; end if;
  if p_seconds is null or p_seconds < 0 or p_seconds > 14400 then raise exception 'time out of range'; end if;
  cleared := p_level - 1;

  -- every cleared level takes real time
  if p_seconds < cleared * 8 then raise exception 'too fast'; end if;

  for k, n in select key, value::int from jsonb_each_text(coalesce(p_counts, '{}'::jsonb)) loop
    if not (vals ? k) or n < 0 or n > 1000 then raise exception 'unknown waffle'; end if;
    total := total + n * (vals->>k)::int;
    if k = 'plain' then plain_n := n; else special_n := special_n + n; end if;
  end loop;

  -- Grumble drops at most 5 regular and 2 special waffles per knockout,
  -- plus the odd mid-level fumble.
  if plain_n > cleared * 5 + p_seconds / 5 + 1 then raise exception 'too many waffles'; end if;
  if special_n > cleared * 2 + p_seconds / 30 + 1 then raise exception 'too many special waffles'; end if;
  if coalesce((p_counts->>'lotto')::int, 0) > 1 + special_n / 40 then raise exception 'too lucky'; end if;
  if coalesce((p_counts->>'truck')::int, 0) > 1 + special_n / 10 then raise exception 'too lucky'; end if;

  select * into r from public.waffle_board where id = uid for update;
  if found and r.last_run_at > now() - interval '10 seconds' then raise exception 'slow down'; end if;

  insert into public.waffle_board as b (id, waffles, best, runs, last_run_at, updated_at)
  values (uid, total, p_level, 1, now(), now())
  on conflict (id) do update
    set waffles = b.waffles + excluded.waffles,
        best = greatest(b.best, excluded.best),
        runs = b.runs + 1,
        last_run_at = now(),
        updated_at = now()
  returning * into r;
  insert into public.waffle_runs (player, waffles, level) values (uid, total, p_level);
  return r;
end;
$$;

revoke all on function public.submit_run(jsonb, int, int) from public, anon;
grant execute on function public.submit_run(jsonb, int, int) to authenticated;

-- ---------------------------------------------------------------------------
-- Profiles: just a board name and a picture. To move to a new phone, the old
-- phone shows a one-time move code that's typed into the new phone.
-- ---------------------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

alter table public.waffle_board add column if not exists pfp text;
alter table public.waffle_board add column if not exists move_code text;
alter table public.waffle_board add column if not exists move_expires timestamptz;
-- Waffle wallet: "waffles" = earned by playing (the only number on the board),
-- "bought" = purchased waffles, "spent" = spent in the store.
alter table public.waffle_board add column if not exists bought bigint not null default 0 check (bought >= 0);
alter table public.waffle_board add column if not exists spent bigint not null default 0 check (spent >= 0);
alter table public.waffle_board add column if not exists owned text[] not null default '{}';
drop function if exists public.login_profile(text, text);
drop function if exists public.set_nick(text);
drop function if exists public.save_profile(text, text);
alter table public.waffle_board drop column if exists pin_hash;
alter table public.waffle_board drop column if exists pin_fails;
alter table public.waffle_board drop column if exists locked_until;

-- Move codes stay private: players can read every other column.
revoke select on public.waffle_board from anon, authenticated;
grant select (id, nick, pfp, waffles, best, runs, updated_at) on public.waffle_board to anon, authenticated;

-- One player per name (capital letters don't count as different).
update public.waffle_board b set nick = left(b.nick, 9) || '-' || left(b.id::text, 4)
where b.nick is not null
  and exists (select 1 from public.waffle_board o where lower(o.nick) = lower(b.nick) and o.id < b.id);
create unique index if not exists waffle_board_nick_key on public.waffle_board (lower(nick));

create or replace function public.my_profile()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select jsonb_build_object('nick', nick, 'pfp', pfp, 'waffles', waffles, 'best', best, 'runs', runs,
                               'wallet', waffles + bought - spent, 'bought', bought, 'owned', to_jsonb(owned))
       from public.waffle_board where id = auth.uid()),
    '{}'::jsonb);
$$;

-- Create a profile or change your name.
create or replace function public.save_profile(p_nick text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  clean text := trim(coalesce(p_nick, ''));
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  if clean !~ '^[A-Za-z0-9 _.-]{2,14}$' then return jsonb_build_object('ok', false, 'reason', 'bad_name'); end if;
  if exists (select 1 from public.waffle_board where lower(nick) = lower(clean) and id <> uid) then
    return jsonb_build_object('ok', false, 'reason', 'name_taken');
  end if;
  insert into public.waffle_board as b (id, nick) values (uid, clean)
  on conflict (id) do update set nick = excluded.nick, updated_at = now();
  return jsonb_build_object('ok', true, 'nick', clean);
end;
$$;

-- Old phone: get a one-time code (good for 15 minutes).
create or replace function public.get_move_code()
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  uid uuid := auth.uid();
  abc text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  b bytea := gen_random_bytes(6);
  code text := '';
  i int;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  if not exists (select 1 from public.waffle_board where id = uid and nick is not null) then
    return jsonb_build_object('ok', false, 'reason', 'no_profile');
  end if;
  for i in 0..5 loop code := code || substr(abc, 1 + get_byte(b, i) % length(abc), 1); end loop;
  update public.waffle_board set move_code = code, move_expires = now() + interval '15 minutes' where id = uid;
  return jsonb_build_object('ok', true, 'code', code);
end;
$$;

-- New phone: type the code to bring the profile over. Waffles earned on the
-- new phone before moving get added to the profile.
create or replace function public.use_move_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  r public.waffle_board;
  m public.waffle_board;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  select * into r from public.waffle_board
   where move_code = upper(replace(trim(coalesce(p_code, '')), ' ', '')) and move_expires > now()
   for update;
  if not found then return jsonb_build_object('ok', false, 'reason', 'bad_code'); end if;
  if r.id = uid then return jsonb_build_object('ok', true, 'nick', r.nick, 'waffles', r.waffles); end if;
  select * into m from public.waffle_board where id = uid for update;
  if found and m.nick is not null then return jsonb_build_object('ok', false, 'reason', 'switch_needed'); end if;
  if found then delete from public.waffle_board where id = uid; end if;
  update public.waffle_board
     set id = uid,
         waffles = r.waffles + coalesce(m.waffles, 0),
         best = greatest(r.best, coalesce(m.best, 0)),
         runs = r.runs + coalesce(m.runs, 0),
         move_code = null,
         move_expires = null,
         updated_at = now()
   where id = r.id;
  update public.waffle_runs set player = uid where player = r.id;
  return jsonb_build_object('ok', true, 'nick', r.nick, 'waffles', r.waffles + coalesce(m.waffles, 0));
end;
$$;

-- Profile picture: one of the game's characters on a colored background.
create or replace function public.set_pfp(p_pfp text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare uid uuid := auth.uid();
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  if p_pfp !~ '^(todd|booster|grumble|waffle):(red|gold|sky|mint|pink|purple)$' then
    return jsonb_build_object('ok', false, 'reason', 'bad_pfp');
  end if;
  insert into public.waffle_board as b (id, pfp) values (uid, p_pfp)
  on conflict (id) do update set pfp = excluded.pfp, updated_at = now();
  return jsonb_build_object('ok', true, 'pfp', p_pfp);
end;
$$;

revoke all on function public.my_profile() from public, anon;
revoke all on function public.save_profile(text) from public, anon;
revoke all on function public.get_move_code() from public, anon;
revoke all on function public.use_move_code(text) from public, anon;
revoke all on function public.set_pfp(text) from public, anon;
grant execute on function public.my_profile() to authenticated;
grant execute on function public.save_profile(text) to authenticated;
grant execute on function public.get_move_code() to authenticated;
grant execute on function public.use_move_code(text) to authenticated;
grant execute on function public.set_pfp(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Waffle Store: spend waffles on Super Duper Weapons. Prices live here, so the
-- game can't be tricked into a discount. Spending never touches the board.
-- ---------------------------------------------------------------------------
create or replace function public.buy_item(p_item text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  prices jsonb := '{"ivy":250,"porcu":750,"beans":2000}';
  price bigint;
  r public.waffle_board;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  if not (prices ? p_item) then return jsonb_build_object('ok', false, 'reason', 'bad_item'); end if;
  price := (prices->>p_item)::bigint;
  select * into r from public.waffle_board where id = uid for update;
  if not found then return jsonb_build_object('ok', false, 'reason', 'not_enough', 'wallet', 0); end if;
  if p_item = any(r.owned) then
    return jsonb_build_object('ok', true, 'wallet', r.waffles + r.bought - r.spent, 'owned', to_jsonb(r.owned));
  end if;
  if r.waffles + r.bought - r.spent < price then
    return jsonb_build_object('ok', false, 'reason', 'not_enough', 'wallet', r.waffles + r.bought - r.spent);
  end if;
  update public.waffle_board set spent = spent + price, owned = array_append(owned, p_item), updated_at = now()
   where id = uid returning * into r;
  return jsonb_build_object('ok', true, 'wallet', r.waffles + r.bought - r.spent, 'owned', to_jsonb(r.owned));
end;
$$;
revoke all on function public.buy_item(text) from public, anon;
grant execute on function public.buy_item(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 24-hour Waffle Tournaments: every run is logged, and a tournament ranks
-- players by waffles earned between its start and end.
-- ---------------------------------------------------------------------------
create table if not exists public.waffle_runs (
  id bigserial primary key,
  player uuid not null references auth.users(id) on delete cascade,
  waffles bigint not null,
  level int not null,
  created_at timestamptz not null default now()
);
create index if not exists waffle_runs_time on public.waffle_runs (created_at);
alter table public.waffle_runs enable row level security;
revoke all on public.waffle_runs from anon, authenticated;

create table if not exists public.tournaments (
  id serial primary key,
  title text not null,
  prize text,
  starts_at timestamptz not null,
  ends_at timestamptz not null
);
alter table public.tournaments enable row level security;
drop policy if exists "Anyone can see tournaments" on public.tournaments;
create policy "Anyone can see tournaments" on public.tournaments for select using (true);
revoke insert, update, delete, truncate, references, trigger on public.tournaments from anon, authenticated;
grant select on public.tournaments to anon, authenticated;

-- The live tournament (or the most recent one), with its top 10.
create or replace function public.tournament_board()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with t as (
    select * from public.tournaments
    order by (now() between starts_at and ends_at) desc, ends_at desc
    limit 1
  ), top as (
    select b.id, b.nick, b.pfp, sum(w.waffles) as waffles
    from t
    join public.waffle_runs w on w.created_at between t.starts_at and t.ends_at
    join public.waffle_board b on b.id = w.player
    group by b.id, b.nick, b.pfp
    order by sum(w.waffles) desc
    limit 10
  )
  select coalesce(
    (select jsonb_build_object('id', t.id, 'title', t.title, 'prize', t.prize,
              'starts_at', t.starts_at, 'ends_at', t.ends_at, 'live', now() between t.starts_at and t.ends_at,
              'rows', coalesce((select jsonb_agg(to_jsonb(top)) from top), '[]'::jsonb))
       from t),
    '{}'::jsonb);
$$;
revoke all on function public.tournament_board() from public;
grant execute on function public.tournament_board() to anon, authenticated;

-- ===== 2026-10-14: Legends + one profile on many devices =====
-- Bonkd: Legends for every tournament player, and one profile across phone + computer.

-- Tournaments can name a Legend. Everyone who played during that tournament unlocks it.
alter table public.tournaments add column if not exists legend text;
alter table public.tournaments add column if not exists legend_name text;

-- Extra devices linked to a profile (the profile's own first device isn't listed here).
create table if not exists public.profile_devices (
  device uuid primary key references auth.users(id) on delete cascade,
  profile uuid not null references public.waffle_board(id) on delete cascade,
  linked_at timestamptz not null default now()
);
alter table public.profile_devices enable row level security;
revoke all on public.profile_devices from anon, authenticated;

-- The profile this device plays as.
create or replace function public.bonkd_me()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select profile from public.profile_devices where device = auth.uid()), auth.uid());
$$;
revoke all on function public.bonkd_me() from public, anon, authenticated;

create or replace function public.submit_run(p_counts jsonb, p_level int, p_seconds int)
returns public.waffle_board
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  pid uuid;
  vals jsonb := '{"plain":1,"chicken":5,"report":7,"unicorn":10,"ring":25,"refund":50,"tree":100,"barrow":150,"truck":333,"lotto":2000}';
  k text;
  n int;
  total bigint := 0;
  plain_n int := 0;
  special_n int := 0;
  cleared int;
  r public.waffle_board;
begin
  if uid is null then raise exception 'not signed in'; end if;
  pid := public.bonkd_me();
  if p_level is null or p_level < 1 or p_level > 500 then raise exception 'level out of range'; end if;
  if p_seconds is null or p_seconds < 0 or p_seconds > 14400 then raise exception 'time out of range'; end if;
  cleared := p_level - 1;
  if p_seconds < cleared * 8 then raise exception 'too fast'; end if;
  for k, n in select key, value::int from jsonb_each_text(coalesce(p_counts, '{}'::jsonb)) loop
    if not (vals ? k) or n < 0 or n > 1000 then raise exception 'unknown waffle'; end if;
    total := total + n * (vals->>k)::int;
    if k = 'plain' then plain_n := n; else special_n := special_n + n; end if;
  end loop;
  if plain_n > cleared * 5 + p_seconds / 5 + 1 then raise exception 'too many waffles'; end if;
  if special_n > cleared * 2 + p_seconds / 30 + 1 then raise exception 'too many special waffles'; end if;
  if coalesce((p_counts->>'lotto')::int, 0) > 1 + special_n / 40 then raise exception 'too lucky'; end if;
  if coalesce((p_counts->>'truck')::int, 0) > 1 + special_n / 10 then raise exception 'too lucky'; end if;
  select * into r from public.waffle_board where id = pid for update;
  if found and r.last_run_at > now() - interval '10 seconds' then raise exception 'slow down'; end if;
  insert into public.waffle_board as b (id, waffles, best, runs, last_run_at, updated_at)
  values (pid, total, p_level, 1, now(), now())
  on conflict (id) do update
    set waffles = b.waffles + excluded.waffles,
        best = greatest(b.best, excluded.best),
        runs = b.runs + 1,
        last_run_at = now(),
        updated_at = now()
  returning * into r;
  insert into public.waffle_runs (player, waffles, level) values (pid, total, p_level);
  return r;
end;
$$;

create or replace function public.my_profile()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select jsonb_build_object('id', b.id, 'nick', b.nick, 'pfp', b.pfp, 'waffles', b.waffles, 'best', b.best, 'runs', b.runs,
                               'wallet', b.waffles + b.bought - b.spent, 'bought', b.bought, 'owned', to_jsonb(b.owned),
                               'devices', 1 + (select count(*) from public.profile_devices d where d.profile = b.id),
                               'legends', coalesce((select jsonb_agg(t.legend order by t.ends_at) from public.tournaments t
                                                     where t.legend is not null
                                                       and exists (select 1 from public.waffle_runs w
                                                                    where w.player = b.id and w.created_at between t.starts_at and t.ends_at)), '[]'::jsonb))
       from public.waffle_board b where b.id = public.bonkd_me()),
    '{}'::jsonb);
$$;

create or replace function public.save_profile(p_nick text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  pid uuid;
  clean text := trim(coalesce(p_nick, ''));
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  if clean !~ '^[A-Za-z0-9 _.-]{2,14}$' then return jsonb_build_object('ok', false, 'reason', 'bad_name'); end if;
  if exists (select 1 from public.waffle_board where lower(nick) = lower(clean) and id <> pid) then
    return jsonb_build_object('ok', false, 'reason', 'name_taken');
  end if;
  insert into public.waffle_board as b (id, nick) values (pid, clean)
  on conflict (id) do update set nick = excluded.nick, updated_at = now();
  return jsonb_build_object('ok', true, 'nick', clean);
end;
$$;

-- Any device on a profile can make a one-time link code (good for 15 minutes).
create or replace function public.get_move_code()
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  pid uuid;
  abc text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  b bytea := gen_random_bytes(6);
  code text := '';
  i int;
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  if not exists (select 1 from public.waffle_board where id = pid and nick is not null) then
    return jsonb_build_object('ok', false, 'reason', 'no_profile');
  end if;
  for i in 0..5 loop code := code || substr(abc, 1 + get_byte(b, i) % length(abc), 1); end loop;
  update public.waffle_board set move_code = code, move_expires = now() + interval '15 minutes' where id = pid;
  return jsonb_build_object('ok', true, 'code', code);
end;
$$;

-- Type a link code on another phone or computer: that device joins the profile.
-- Both devices keep working. Waffles this device earned before linking are added in.
create or replace function public.use_move_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  pid uuid;
  r public.waffle_board;
  m public.waffle_board;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  select * into r from public.waffle_board
   where move_code = upper(replace(trim(coalesce(p_code, '')), ' ', '')) and move_expires > now()
   for update;
  if not found then return jsonb_build_object('ok', false, 'reason', 'bad_code'); end if;
  if r.id = pid then return jsonb_build_object('ok', true, 'nick', r.nick, 'waffles', r.waffles); end if;
  select * into m from public.waffle_board where id = pid for update;
  if found and m.nick is not null then return jsonb_build_object('ok', false, 'reason', 'switch_needed'); end if;
  if found then
    update public.waffle_board
       set waffles = r.waffles + m.waffles, best = greatest(r.best, m.best), runs = r.runs + m.runs,
           bought = r.bought + m.bought, spent = r.spent + m.spent,
           owned = array(select distinct x from unnest(r.owned || m.owned) x),
           updated_at = now()
     where id = r.id returning * into r;
    update public.waffle_runs set player = r.id where player = pid;
    update public.waffle_board set waffles = 0, best = 0, runs = 0, bought = 0, spent = 0, owned = '{}' where id = pid;
  end if;
  insert into public.profile_devices (device, profile) values (uid, r.id)
  on conflict (device) do update set profile = excluded.profile, linked_at = now();
  update public.waffle_board set move_code = null, move_expires = null where id = r.id;
  return jsonb_build_object('ok', true, 'nick', r.nick, 'waffles', r.waffles);
end;
$$;

create or replace function public.set_pfp(p_pfp text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare pid uuid;
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  if p_pfp !~ '^(todd|booster|grumble|waffle):(red|gold|sky|mint|pink|purple)$' then
    return jsonb_build_object('ok', false, 'reason', 'bad_pfp');
  end if;
  insert into public.waffle_board as b (id, pfp) values (pid, p_pfp)
  on conflict (id) do update set pfp = excluded.pfp, updated_at = now();
  return jsonb_build_object('ok', true, 'pfp', p_pfp);
end;
$$;

create or replace function public.buy_item(p_item text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  pid uuid;
  prices jsonb := '{"ivy":250,"porcu":750,"beans":2000}';
  price bigint;
  r public.waffle_board;
begin
  if auth.uid() is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  pid := public.bonkd_me();
  if not (prices ? p_item) then return jsonb_build_object('ok', false, 'reason', 'bad_item'); end if;
  price := (prices->>p_item)::bigint;
  select * into r from public.waffle_board where id = pid for update;
  if not found then return jsonb_build_object('ok', false, 'reason', 'not_enough', 'wallet', 0); end if;
  if p_item = any(r.owned) then
    return jsonb_build_object('ok', true, 'wallet', r.waffles + r.bought - r.spent, 'owned', to_jsonb(r.owned));
  end if;
  if r.waffles + r.bought - r.spent < price then
    return jsonb_build_object('ok', false, 'reason', 'not_enough', 'wallet', r.waffles + r.bought - r.spent);
  end if;
  update public.waffle_board set spent = spent + price, owned = array_append(owned, p_item), updated_at = now()
   where id = pid returning * into r;
  return jsonb_build_object('ok', true, 'wallet', r.waffles + r.bought - r.spent, 'owned', to_jsonb(r.owned));
end;
$$;

create or replace function public.tournament_board()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with t as (
    select * from public.tournaments
    order by (now() between starts_at and ends_at) desc, ends_at desc
    limit 1
  ), top as (
    select b.id, b.nick, b.pfp, sum(w.waffles) as waffles
    from t
    join public.waffle_runs w on w.created_at between t.starts_at and t.ends_at
    join public.waffle_board b on b.id = w.player
    group by b.id, b.nick, b.pfp
    order by sum(w.waffles) desc
    limit 10
  )
  select coalesce(
    (select jsonb_build_object('id', t.id, 'title', t.title, 'prize', t.prize, 'legend', t.legend, 'legend_name', t.legend_name,
              'starts_at', t.starts_at, 'ends_at', t.ends_at, 'live', now() between t.starts_at and t.ends_at,
              'players', (select count(distinct w.player) from public.waffle_runs w where w.created_at between t.starts_at and t.ends_at),
              'rows', coalesce((select jsonb_agg(to_jsonb(top)) from top), '[]'::jsonb))
       from t),
    '{}'::jsonb);
$$;

revoke all on function public.submit_run(jsonb, int, int) from public, anon;
revoke all on function public.my_profile() from public, anon;
revoke all on function public.save_profile(text) from public, anon;
revoke all on function public.get_move_code() from public, anon;
revoke all on function public.use_move_code(text) from public, anon;
revoke all on function public.set_pfp(text) from public, anon;
revoke all on function public.buy_item(text) from public, anon;
grant execute on function public.submit_run(jsonb, int, int) to authenticated;
grant execute on function public.my_profile() to authenticated;
grant execute on function public.save_profile(text) to authenticated;
grant execute on function public.get_move_code() to authenticated;
grant execute on function public.use_move_code(text) to authenticated;
grant execute on function public.set_pfp(text) to authenticated;
grant execute on function public.buy_item(text) to authenticated;
grant execute on function public.tournament_board() to anon, authenticated;

-- 2026-10-14 (later): new waffle values
create or replace function public.submit_run(p_counts jsonb, p_level int, p_seconds int)
returns public.waffle_board
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  pid uuid;
  vals jsonb := '{"plain":5,"chicken":25,"report":100,"unicorn":250,"ring":1000,"refund":500,"tree":5000,"barrow":2000,"truck":10000,"lotto":25000}';
  k text;
  n int;
  total bigint := 0;
  plain_n int := 0;
  special_n int := 0;
  cleared int;
  r public.waffle_board;
begin
  if uid is null then raise exception 'not signed in'; end if;
  pid := public.bonkd_me();
  if p_level is null or p_level < 1 or p_level > 500 then raise exception 'level out of range'; end if;
  if p_seconds is null or p_seconds < 0 or p_seconds > 14400 then raise exception 'time out of range'; end if;
  cleared := p_level - 1;
  if p_seconds < cleared * 8 then raise exception 'too fast'; end if;
  for k, n in select key, value::int from jsonb_each_text(coalesce(p_counts, '{}'::jsonb)) loop
    if not (vals ? k) or n < 0 or n > 1000 then raise exception 'unknown waffle'; end if;
    total := total + n * (vals->>k)::int;
    if k = 'plain' then plain_n := n; else special_n := special_n + n; end if;
  end loop;
  if plain_n > cleared * 5 + p_seconds / 5 + 1 then raise exception 'too many waffles'; end if;
  if special_n > cleared * 2 + p_seconds / 30 + 1 then raise exception 'too many special waffles'; end if;
  if coalesce((p_counts->>'lotto')::int, 0) > 1 + special_n / 40 then raise exception 'too lucky'; end if;
  if coalesce((p_counts->>'truck')::int, 0) > 1 + special_n / 10 then raise exception 'too lucky'; end if;
  select * into r from public.waffle_board where id = pid for update;
  if found and r.last_run_at > now() - interval '10 seconds' then raise exception 'slow down'; end if;
  insert into public.waffle_board as b (id, waffles, best, runs, last_run_at, updated_at)
  values (pid, total, p_level, 1, now(), now())
  on conflict (id) do update
    set waffles = b.waffles + excluded.waffles,
        best = greatest(b.best, excluded.best),
        runs = b.runs + 1,
        last_run_at = now(),
        updated_at = now()
  returning * into r;
  insert into public.waffle_runs (player, waffles, level) values (pid, total, p_level);
  return r;
end;
$$;
