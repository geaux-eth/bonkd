-- Bonkd: new waffle values (plain 5 ... lotto 25,000).

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
