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
  return r;
end;
$$;

revoke all on function public.submit_run(jsonb, int, int) from public, anon;
grant execute on function public.submit_run(jsonb, int, int) to authenticated;

-- ---------------------------------------------------------------------------
-- Profiles: a board name plus a 4-digit PIN, so a player can log in on
-- another phone and keep their waffles. Everything happens inside the game.
-- ---------------------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

alter table public.waffle_board add column if not exists pin_hash text;
alter table public.waffle_board add column if not exists pin_fails int not null default 0;
alter table public.waffle_board add column if not exists locked_until timestamptz;

-- PINs stay private: players can read every column except the PIN ones.
revoke select on public.waffle_board from anon, authenticated;
grant select (id, nick, waffles, best, runs, updated_at) on public.waffle_board to anon, authenticated;

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
    (select jsonb_build_object('nick', nick, 'has_pin', pin_hash is not null, 'waffles', waffles, 'best', best, 'runs', runs)
       from public.waffle_board where id = auth.uid()),
    '{}'::jsonb);
$$;

-- Create a profile, or change your name (pass p_pin = null to keep your PIN).
create or replace function public.save_profile(p_nick text, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  uid uuid := auth.uid();
  clean text := trim(coalesce(p_nick, ''));
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  if clean !~ '^[A-Za-z0-9 _.-]{2,14}$' then return jsonb_build_object('ok', false, 'reason', 'bad_name'); end if;
  if p_pin is not null and p_pin !~ '^[0-9]{4}$' then return jsonb_build_object('ok', false, 'reason', 'bad_pin'); end if;
  if exists (select 1 from public.waffle_board where lower(nick) = lower(clean) and id <> uid) then
    return jsonb_build_object('ok', false, 'reason', 'name_taken');
  end if;
  insert into public.waffle_board as b (id, nick, pin_hash)
  values (uid, clean, case when p_pin is null then null else crypt(p_pin, gen_salt('bf')) end)
  on conflict (id) do update
    set nick = excluded.nick,
        pin_hash = coalesce(excluded.pin_hash, b.pin_hash),
        updated_at = now();
  return jsonb_build_object('ok', true, 'nick', clean);
end;
$$;

-- Log in to an existing profile from this phone. Waffles earned here before
-- logging in are added to the profile. Five wrong PINs locks it for 15 minutes.
create or replace function public.login_profile(p_nick text, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  uid uuid := auth.uid();
  r public.waffle_board;
  m public.waffle_board;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  select * into r from public.waffle_board where lower(nick) = lower(trim(coalesce(p_nick, ''))) for update;
  if not found or r.pin_hash is null then return jsonb_build_object('ok', false, 'reason', 'no_profile'); end if;
  if r.locked_until is not null and r.locked_until > now() then return jsonb_build_object('ok', false, 'reason', 'locked'); end if;
  if r.pin_hash <> crypt(coalesce(p_pin, ''), r.pin_hash) then
    update public.waffle_board
       set pin_fails = pin_fails + 1,
           locked_until = case when pin_fails + 1 >= 5 then now() + interval '15 minutes' else locked_until end
     where id = r.id;
    return jsonb_build_object('ok', false, 'reason', 'wrong_pin');
  end if;
  if r.id = uid then
    update public.waffle_board set pin_fails = 0, locked_until = null where id = uid;
    return jsonb_build_object('ok', true, 'nick', r.nick, 'waffles', r.waffles);
  end if;
  select * into m from public.waffle_board where id = uid for update;
  if found and m.pin_hash is not null then
    return jsonb_build_object('ok', false, 'reason', 'switch_needed');
  end if;
  if found then delete from public.waffle_board where id = uid; end if;
  update public.waffle_board
     set id = uid,
         waffles = r.waffles + coalesce(m.waffles, 0),
         best = greatest(r.best, coalesce(m.best, 0)),
         runs = r.runs + coalesce(m.runs, 0),
         pin_fails = 0,
         locked_until = null,
         updated_at = now()
   where id = r.id;
  return jsonb_build_object('ok', true, 'nick', r.nick, 'waffles', r.waffles + coalesce(m.waffles, 0));
end;
$$;

-- Older versions of the game called set_nick; it now follows the same name rules.
drop function if exists public.set_nick(text);
create or replace function public.set_nick(p_nick text)
returns jsonb
language sql
security definer
set search_path = public
as $$ select public.save_profile(p_nick, null); $$;

revoke all on function public.my_profile() from public, anon;
revoke all on function public.save_profile(text, text) from public, anon;
revoke all on function public.login_profile(text, text) from public, anon;
grant execute on function public.my_profile() to authenticated;
grant execute on function public.save_profile(text, text) to authenticated;
grant execute on function public.login_profile(text, text) to authenticated;
revoke all on function public.set_nick(text) from public, anon;
grant execute on function public.set_nick(text) to authenticated;
