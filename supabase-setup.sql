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
-- Profiles: just a board name and a picture. To move to a new phone, the old
-- phone shows a one-time move code that's typed into the new phone.
-- ---------------------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

alter table public.waffle_board add column if not exists pfp text;
alter table public.waffle_board add column if not exists move_code text;
alter table public.waffle_board add column if not exists move_expires timestamptz;
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
    (select jsonb_build_object('nick', nick, 'pfp', pfp, 'waffles', waffles, 'best', best, 'runs', runs)
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
