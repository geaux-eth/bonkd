-- Bonkd Waffle Board: run this once in Supabase > SQL Editor
create table if not exists public.waffle_board (
  id uuid primary key references auth.users(id) on delete cascade,
  nick text check (char_length(nick) <= 14),
  waffles bigint not null default 0 check (waffles >= 0),
  best int not null default 0,
  runs int not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.waffle_board enable row level security;
create policy "Anyone can read the board" on public.waffle_board for select using (true);
create policy "Players add their own row" on public.waffle_board for insert with check (auth.uid() = id);
create policy "Players update their own row" on public.waffle_board for update using (auth.uid() = id) with check (auth.uid() = id);
