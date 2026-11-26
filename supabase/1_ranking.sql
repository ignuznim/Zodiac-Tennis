-- 십이지 테니스 · 1. 랭킹: the scores table (wins against the computer). Run this first.
-- Run in Supabase: SQL Editor -> New query -> paste all of it -> Run.
-- Safe to run again: it only adds what is missing and replaces its own functions and rules; saved data stays.

create table if not exists public.scores (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  nickname    text     not null check (char_length(btrim(nickname)) between 1 and 8),
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
-- nicknames are 1 to 8 letters (no record has a longer one since 2026-11-19)
alter table public.scores drop constraint if exists scores_nickname_check;
alter table public.scores add constraint scores_nickname_check check (char_length(btrim(nickname)) between 1 and 8);
-- perfect hits in a chain: each one after the first adds up to 9 to this count, and 2 points a count to the score
alter table public.scores add column if not exists combo integer not null default 0 check (combo between 0 and 300000);
-- every ball the player struck, and the longest run of perfect hits: a person misses now and then
alter table public.scores add column if not exists hits integer check (hits between 0 and 100000);
alter table public.scores add column if not exists streak integer check (streak between 0 and 100000);
-- what the player wore, hat,uniform,shoes,racket (2_wardrobe.sql adds it too; here so the grants below can name it)
alter table public.scores add column if not exists gear text check (gear is null or char_length(gear) <= 40);
-- a record kept on the month's board but left out of 명예의 전당 (set only here, by hand, for records found to be cheats)
alter table public.scores add column if not exists no_fame boolean not null default false;
-- why a record looks unlike a person's play (set by the check below, read by the owner in scores_suspect); such a record is kept, but out of 명예의 전당
alter table public.scores add column if not exists suspect text;

-- The score is worked out here, never taken from the browser, and a record that could not
-- come from a real match is refused.
-- Since 2026-11-26: only what no match can hold is refused. What a person seldom does is let in, marked
-- (suspect) and kept out of 명예의 전당, for the owner to look at: one strong sign is enough, weak signs need two.
-- A whole match without losing a point is possible (the owner won 16:0 on 보통), so on its own it marks nothing.
create or replace function public.scores_check() returns trigger
language plpgsql security definer set search_path = public as $$
declare min_pts int; strong text[] := '{}'; weak text[] := '{}';
begin
  new.nickname   := btrim(new.nickname);
  new.created_at := now();
  -- a member's nickname belongs to that member: anyone else (signed in or not) must pick another.
  -- Names are 1 to 8 letters.
  if to_regclass('public.profiles') is not null then
    if exists (select 1 from public.profiles p where p.nickname = new.nickname and p.id is distinct from auth.uid()) then
      raise exception 'nickname taken';
    end if;
  end if;
  if char_length(new.nickname) > 8 then raise exception 'bad nickname'; end if;
  min_pts := case new.mode when 'flash' then 10 when 'short' then 16 else 72 end; -- the fewest points a win can take
  if new.pts_for < min_pts then raise exception 'not a finished win'; end if;
  if new.duration_s < (new.pts_for + new.pts_against) * 3 then raise exception 'too fast'; end if;
  if new.sweet > (new.pts_for + new.pts_against) * 25 then raise exception 'too many sweet hits'; end if;
  if new.combo > new.sweet * 9 then raise exception 'too many sweet hits'; end if;
  if new.hits is null or new.streak is null then raise exception 'old client'; end if;
  if new.sweet > new.hits or new.streak > new.sweet then raise exception 'not a real match'; end if;
  -- strong signs: perfect on almost every ball, or a run of perfect hits no hand keeps up
  if new.hits >= 20 and new.sweet > new.hits * 0.85 then strong := array_append(strong, '딱! 85% 넘음'::text); end if;
  if new.streak > 30 then strong := array_append(strong, '연속 딱! 30 넘음'::text); end if;
  -- weak signs: each alone happens in real play
  if new.level = 3 and new.pts_against = 0 and new.pts_for >= 16 then weak := array_append(weak, '어려움 무실점'::text); end if;
  if new.hits >= 20 and new.sweet > new.hits * 0.65 and new.sweet <= new.hits * 0.85 then weak := array_append(weak, '딱! 65% 넘음'::text); end if;
  if new.streak > 15 and new.streak <= 30 then weak := array_append(weak, '연속 딱! 15 넘음'::text); end if;
  if new.duration_s < (new.pts_for + new.pts_against) * 5 then weak := array_append(weak, '포인트당 5초 미만'::text); end if;
  new.suspect := null; new.no_fame := false;
  if cardinality(strong) > 0 or cardinality(weak) >= 2 then
    new.suspect := array_to_string(strong || weak, ', '); new.no_fame := true;
  end if;
  if exists (select 1 from public.scores s where s.client_id = new.client_id and s.created_at > now() - interval '20 seconds') then
    raise exception 'slow down';
  end if;
  -- what the match held (a win, the margin, the perfect hits and the chains), times the level: easy x1, normal x1.35, hard x1.8
  new.score := round((300 + greatest(0, new.pts_for - new.pts_against) * 30 + new.sweet * 6 + new.combo * 6)
             * (case new.level when 1 then 100 when 2 then 135 else 180 end) / 100.0);
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
grant select (id, created_at, nickname, mode, level, animal, opponent, court, sets, pts_for, pts_against, sweet, combo, hits, streak, duration_s, score, gear, no_fame)
  on public.scores to anon, authenticated;
grant insert (nickname, mode, level, animal, opponent, court, sets, pts_for, pts_against, sweet, combo, hits, streak, duration_s, client_id, gear)
  on public.scores to anon, authenticated;

-- One record per match: a double tap once sent the same win twice. Drop the repeats, keep the first,
-- and let the database refuse a repeat from now on (the game reads the refusal as "already sent").
delete from public.scores a using public.scores b
 where a.id > b.id and a.client_id = b.client_id and a.mode = b.mode and a.score = b.score
   and a.duration_s = b.duration_s and a.pts_for = b.pts_for and a.pts_against = b.pts_against;
create unique index if not exists scores_one_per_match on public.scores (client_id, mode, score, duration_s, pts_for, pts_against);

-- The score for every record, worked out again by today's sum (since 2026-11-18: (300 + margin x30 + perfect hits x6 + chain x6) x level).
-- Running this again changes nothing: a record already on today's sum keeps its score.
update public.scores set score = round((300 + greatest(0, pts_for - pts_against) * 30 + sweet * 6 + combo * 6)
    * (case level when 1 then 100 when 2 then 135 else 180 end) / 100.0)
  where score is distinct from round((300 + greatest(0, pts_for - pts_against) * 30 + sweet * 6 + combo * 6)
    * (case level when 1 then 100 when 2 then 135 else 180 end) / 100.0);

-- The marked records, newest first, for the owner (Table Editor). A record found to be fair play goes back in with:
--   update public.scores set no_fame = false, suspect = null where id = <id>;
create or replace view public.scores_suspect as
  select id, created_at, nickname, mode, level, sets, pts_for, pts_against, hits, sweet, streak, combo, duration_s, score, suspect, no_fame
    from public.scores where suspect is not null order by created_at desc;
revoke all on public.scores_suspect from anon, authenticated;

-- Records checked by hand and found to be cheats (2026-11-18 and 19: 72:0 and 16:0 wins over the hard computer, '딱!' far past what a hand can do).
-- They stay on that month's board, but never in 명예의 전당. Running this again changes nothing.
update public.scores set no_fame = true
  where id in (34, 35, 36, 37, 45, 46, 48) and client_id = '4a4959ce-4ee6-4d17-8ab1-b5b1537130d6' and not no_fame;
