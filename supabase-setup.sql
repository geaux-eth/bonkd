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
revoke insert, update, delete on public.waffle_board from anon, authenticated;

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

-- A player's name on the board (14 characters max).
create or replace function public.set_nick(p_nick text)
returns public.waffle_board
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  clean text := nullif(trim(left(trim(coalesce(p_nick, '')), 14)), '');
  r public.waffle_board;
begin
  if uid is null then raise exception 'not signed in'; end if;
  insert into public.waffle_board as b (id, nick)
  values (uid, clean)
  on conflict (id) do update set nick = excluded.nick, updated_at = now()
  returning * into r;
  return r;
end;
$$;

revoke all on function public.submit_run(jsonb, int, int) from public, anon;
revoke all on function public.set_nick(text) from public, anon;
grant execute on function public.submit_run(jsonb, int, int) to authenticated;
grant execute on function public.set_nick(text) to authenticated;
