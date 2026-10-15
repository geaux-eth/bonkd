-- Anonymous play stats. Players can only send events through log_events; nobody can read the table except the project owner.
create table if not exists public.bonkd_events(
  id bigserial primary key,
  at timestamptz not null default now(),
  player uuid not null,
  sess uuid not null,
  dev text,
  t int,
  ev text not null,
  lv smallint,
  k text,
  n bigint,
  m bigint
);
create index if not exists bonkd_events_at on public.bonkd_events(at);
create index if not exists bonkd_events_ev_at on public.bonkd_events(ev, at);
create index if not exists bonkd_events_player on public.bonkd_events(player);
alter table public.bonkd_events enable row level security;

create or replace function public.log_events(p_sess uuid, p_dev text, p_ev jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); c int;
begin
  if uid is null then return 0; end if;
  if jsonb_typeof(p_ev) <> 'array' or jsonb_array_length(p_ev) > 60 then raise exception 'too many events'; end if;
  insert into bonkd_events(player, sess, dev, t, ev, lv, k, n, m)
  select uid, p_sess, left(p_dev, 8),
         case when e->>'t'  ~ '^-?\d{1,9}$'  then (e->>'t')::int end,
         left(e->>'ev', 24),
         case when e->>'lv' ~ '^\d{1,4}$'    then (e->>'lv')::smallint end,
         left(e->>'k', 24),
         case when e->>'n'  ~ '^-?\d{1,15}$' then (e->>'n')::bigint end,
         case when e->>'m'  ~ '^-?\d{1,15}$' then (e->>'m')::bigint end
  from jsonb_array_elements(p_ev) e
  where e->>'ev' ~ '^[a-z_]{1,24}$';
  get diagnostics c = row_count;
  return c;
end $$;
revoke all on function public.log_events(uuid, text, jsonb) from public, anon;
grant execute on function public.log_events(uuid, text, jsonb) to authenticated;
