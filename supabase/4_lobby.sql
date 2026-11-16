-- 십이지 테니스 · 4. 로비: open rooms for quick match and the public room list, and how many players are online.
-- Run in Supabase: SQL Editor -> New query -> paste all of it -> Run.
-- Safe to run again: it only adds what is missing and replaces its own functions and rules; saved data stays.
-- The match itself still runs phone to phone; this only helps strangers find each other.

-- ---- Open rooms: a host keeps its row fresh every few seconds; a row older than 20 seconds is a closed room ----
create table if not exists public.rooms (
  code        text primary key check (code ~ '^[A-Z0-9]{6}$'),
  host        uuid not null default auth.uid() references auth.users (id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 10),
  animal      smallint not null default 0 check (animal between 0 and 11),
  kind        text not null check (kind in ('single', 'coop', 'versus', 'any')),   -- chosen when the room is made
  format      text not null check (format in ('flash', 'short', 'regular', 'any')),
  quick       boolean not null default false,                               -- made by 빠른 대전: starts by itself when full
  seats_taken smallint not null default 1 check (seats_taken between 1 and 4),
  seats_total smallint not null default 2 check (seats_total between 2 and 4),
  status      text not null default 'waiting' check (status in ('waiting', 'playing')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists rooms_open on public.rooms (status, updated_at desc);
alter table public.rooms drop constraint if exists rooms_kind_check; -- older copies allowed no 2:2 협동
alter table public.rooms add constraint rooms_kind_check check (kind in ('single', 'coop', 'versus', 'any'));

-- the server keeps the clock and the owner; one open room per player
create or replace function public.rooms_touch() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := now();
  if tg_op = 'INSERT' then
    new.host := auth.uid(); new.created_at := now();
    delete from public.rooms where host = auth.uid() or updated_at < now() - interval '10 minutes'; -- the player's old room, and long-dead ones
  end if;
  return new;
end $$;
drop trigger if exists rooms_touch on public.rooms;
create trigger rooms_touch before insert or update on public.rooms for each row execute function public.rooms_touch();

alter table public.rooms enable row level security;
drop policy if exists "see open rooms" on public.rooms;
create policy "see open rooms" on public.rooms for select to authenticated using (updated_at > now() - interval '20 seconds');
drop policy if exists "open a room" on public.rooms;
create policy "open a room" on public.rooms for insert to authenticated with check (true);
drop policy if exists "keep my room" on public.rooms;
create policy "keep my room" on public.rooms for update to authenticated using (host = auth.uid()) with check (host = auth.uid());
drop policy if exists "close my room" on public.rooms;
create policy "close my room" on public.rooms for delete to authenticated using (host = auth.uid());
revoke all on public.rooms from anon, authenticated;
grant select, delete on public.rooms to authenticated;
grant insert (code, nickname, animal, kind, format, quick, seats_taken, seats_total, status) on public.rooms to authenticated;
grant update (nickname, animal, kind, format, seats_taken, seats_total, status) on public.rooms to authenticated;

-- ---- Who is around: a signed-in player on the online pages says hello every 20 seconds ----
create table if not exists public.presence (
  user_id uuid primary key references auth.users (id) on delete cascade,
  seen_at timestamptz not null default now()
);
alter table public.presence enable row level security;
revoke all on public.presence from anon, authenticated;

create or replace function public.hello() returns integer -- marks me as here, and answers how many are here (the last minute)
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null then
    insert into public.presence (user_id, seen_at) values (auth.uid(), now())
      on conflict (user_id) do update set seen_at = now();
  end if;
  delete from public.presence where seen_at < now() - interval '1 day';
  return (select count(*) from public.presence where seen_at > now() - interval '60 seconds');
end $$;
revoke all on function public.hello() from public, anon;
grant execute on function public.hello() to authenticated;
