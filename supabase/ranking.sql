-- Zodiac Tennis ranking table. Run once in Supabase: SQL Editor -> New query -> paste -> Run.
-- Safe to run again: it replaces the functions and policies it made before.

create table if not exists public.scores (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  nickname    text     not null check (char_length(btrim(nickname)) between 1 and 10),
  mode        text     not null default 'regular' check (mode in ('flash', 'short', 'regular')),
  level       smallint not null check (level between 1 and 3),
  animal      smallint not null check (animal between 0 and 11),
  opponent    smallint not null check (opponent between 0 and 11),
  court       text     not null check (court in ('hard', 'grass', 'clay')),
  sets        text     not null check (char_length(sets) <= 60),
  pts_for     smallint not null check (pts_for between 0 and 3000),
  pts_against smallint not null check (pts_against between 0 and 3000),
  sweet       smallint not null check (sweet between 0 and 30000),
  duration_s  integer  not null check (duration_s between 0 and 86400),
  client_id   uuid     not null,
  score       integer  not null default 0
);
create index if not exists scores_mode_score on public.scores (mode, score desc);

-- The score is worked out here, never taken from the browser, and a record that could not
-- come from a real match is refused.
create or replace function public.scores_check() returns trigger
language plpgsql security definer set search_path = public as $$
declare min_pts int;
begin
  new.nickname   := btrim(new.nickname);
  new.created_at := now();
  min_pts := case new.mode when 'flash' then 10 when 'short' then 16 else 72 end; -- the fewest points a win can take
  if new.pts_for < min_pts then raise exception 'not a finished win'; end if;
  if new.duration_s < (new.pts_for + new.pts_against) * 3 then raise exception 'too fast'; end if;
  if new.sweet > (new.pts_for + new.pts_against) * 25 then raise exception 'too many sweet hits'; end if;
  if exists (select 1 from public.scores s where s.client_id = new.client_id and s.created_at > now() - interval '20 seconds') then
    raise exception 'slow down';
  end if;
  new.score := (case new.level when 1 then 100 when 2 then 300 else 1000 end)
             + greatest(0, new.pts_for - new.pts_against) * 10
             + new.sweet * 2;
  return new;
end $$;
drop trigger if exists scores_check on public.scores;
create trigger scores_check before insert on public.scores for each row execute function public.scores_check();

-- Anyone may read the board and add a record; nobody can change or delete one from the game.
alter table public.scores enable row level security;
drop policy if exists "read scores" on public.scores;
create policy "read scores" on public.scores for select to anon, authenticated using (true);
drop policy if exists "add scores" on public.scores;
create policy "add scores" on public.scores for insert to anon, authenticated with check (true);

revoke all on public.scores from anon, authenticated;
grant select (id, created_at, nickname, mode, level, animal, opponent, court, sets, pts_for, pts_against, sweet, duration_s, score)
  on public.scores to anon, authenticated;
grant insert (nickname, mode, level, animal, opponent, court, sets, pts_for, pts_against, sweet, duration_s, client_id)
  on public.scores to anon, authenticated;
