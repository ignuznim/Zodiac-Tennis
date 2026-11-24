-- 십이지 테니스 · 6. 플레이 기록: every finished match, won or lost, for the owner to look at. Stands on its own.
-- Run in Supabase: SQL Editor -> New query -> paste all of it -> Run.
-- Safe to run again: it only adds what is missing and replaces its own functions, views and rules; saved data stays.
-- Players can only add a row; nobody can read the rows through the game. The owner reads them in the dashboard:
-- Table Editor -> plays_recent (the latest matches), plays_daily (each day), plays_players (each player), plays_members (each member's totals so far).

create table if not exists public.plays (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  client_id   text check (client_id is null or char_length(client_id) <= 40),  -- the device
  user_id     uuid,                                                           -- the account, when signed in (set by the server)
  nickname    text,                                                           -- the account's nickname then (set by the server)
  kind        text not null check (kind in ('cpu', 'online')),
  doubles     boolean not null default false,
  format      text not null check (format in ('flash', 'short', 'regular')),
  level       smallint check (level is null or level between 1 and 3),        -- the computer's level; empty online
  court       text check (court in ('hard', 'grass', 'clay')),
  animal      smallint check (animal between 0 and 11),
  won         boolean not null,
  sets        text check (sets is null or char_length(sets) <= 40),
  pts_for     integer check (pts_for between 0 and 2000),
  pts_against integer check (pts_against between 0 and 2000),
  sweet       integer check (sweet between 0 and 5000),
  duration_s  integer check (duration_s between 0 and 36000),
  version     text check (version is null or char_length(version) <= 16)
);
-- where a row came from: the game itself, or (for matches before this log began) a record registered on the ranking
alter table public.plays add column if not exists source text not null default 'game' check (source in ('game', 'ranking'));
alter table public.plays add column if not exists score_id bigint unique;
create index if not exists plays_recent_idx on public.plays (created_at desc);
create index if not exists plays_client_idx on public.plays (client_id, created_at desc);

-- Who sent it is the server's to say, and a device can send one match at a time (a repeat within 20 s is dropped)
create or replace function public.plays_stamp() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.client_id is not null and exists (select 1 from public.plays where client_id = new.client_id and created_at > now() - interval '20 seconds') then
    return null;
  end if;
  new.created_at := now();
  new.user_id := auth.uid();
  new.nickname := case when auth.uid() is null then null else (select nickname from public.profiles where id = auth.uid()) end;
  return new;
end $$;
drop trigger if exists plays_stamp on public.plays;
create trigger plays_stamp before insert on public.plays for each row execute function public.plays_stamp();

alter table public.plays enable row level security;
drop policy if exists "add plays" on public.plays;
create policy "add plays" on public.plays for insert to anon, authenticated with check (true);
revoke all on public.plays from anon, authenticated;
grant insert (client_id, kind, doubles, format, level, court, animal, won, sets, pts_for, pts_against, sweet, duration_s, version)
  on public.plays to anon, authenticated;

-- ---- The matches from before this log: the ranking holds every win that was registered, so those come in once ----
-- (only records older than the log's first match from the game, so a match is never in twice; the times and names are the record's own)
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'scores') then
    alter table public.plays disable trigger plays_stamp;
    insert into public.plays (created_at, client_id, nickname, kind, doubles, format, level, court, animal, won, sets, pts_for, pts_against, sweet, duration_s, source, score_id)
      select s.created_at, s.client_id::text, s.nickname, 'cpu', false, s.mode, s.level, s.court, s.animal, true, s.sets, s.pts_for, s.pts_against, s.sweet, s.duration_s, 'ranking', s.id
        from public.scores s
       where not exists (select 1 from public.plays p where p.score_id = s.id)
         and s.created_at < coalesce((select min(p.created_at) from public.plays p where p.source = 'game'), now());
    alter table public.plays enable trigger plays_stamp;
  end if;
end $$;

-- ---- For the owner: three views, in Korean time, readable at a glance in the Table Editor ----
-- A player is their nickname when signed in, or 손님 and the start of the device's id.
create or replace view public.plays_recent with (security_invoker = true) as
  select to_char(p.created_at at time zone 'Asia/Seoul', 'MM-DD HH24:MI') as "시각",
         coalesce(p.nickname, '손님 ' || left(p.client_id, 6)) as "플레이어",
         case p.kind when 'online' then '온라인' else '컴퓨터 ' || p.level end || case when p.doubles then ' · 복식' else '' end as "상대",
         case p.format when 'flash' then '번개전' when 'short' then '단판전' else '정규전' end as "경기",
         case p.court when 'hard' then '하드' when 'grass' then '잔디' else '클레이' end as "코트",
         case when p.won then '승' else '패' end as "결과",
         p.sets as "세트", p.pts_for || ':' || p.pts_against as "포인트", p.sweet as "딱",
         round(p.duration_s / 60.0, 1) as "분", p.version as "버전",
         case p.source when 'ranking' then '랭킹 등록' else '게임' end as "출처"
    from public.plays p
   order by p.created_at desc
   limit 300;

create or replace view public.plays_daily with (security_invoker = true) as
  select (p.created_at at time zone 'Asia/Seoul')::date as "날짜",
         count(*) as "경기",
         count(distinct p.client_id) as "기기",
         count(distinct p.user_id) as "회원",
         count(*) filter (where p.kind = 'online') as "온라인",
         count(*) filter (where p.format = 'flash') as "번개전",
         count(*) filter (where p.format = 'short') as "단판전",
         count(*) filter (where p.format = 'regular') as "정규전",
         round(sum(p.duration_s) / 60.0) as "총 분"
    from public.plays p
   group by 1
   order by 1 desc;

create or replace view public.plays_players with (security_invoker = true) as
  select coalesce(max(p.nickname), '손님 ' || left(max(p.client_id), 6)) as "플레이어",
         count(*) as "경기",
         count(*) filter (where p.won) as "승",
         round(100.0 * count(*) filter (where p.won) / count(*)) as "승률",
         count(*) filter (where p.kind = 'online') as "온라인",
         round(sum(p.duration_s) / 60.0) as "총 분",
         to_char(min(p.created_at) at time zone 'Asia/Seoul', 'MM-DD') as "처음",
         to_char(max(p.created_at) at time zone 'Asia/Seoul', 'MM-DD HH24:MI') as "마지막"
    from public.plays p
   group by coalesce(p.user_id::text, p.client_id)
   order by max(p.created_at) desc;

revoke all on public.plays_recent, public.plays_daily, public.plays_players from anon, authenticated;

-- ---- Each member's counts so far, kept with the account since it was made (every match, not only the registered ones) ----
-- 경기 and 승 count every finished match; a guest's counts stay on their device, so only members are here.
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'profiles') then
    execute $v$
      create or replace view public.plays_members with (security_invoker = true) as
        select coalesce(p.nickname, '(닉네임 없음)') as "회원",
               coalesce((p.progress ->> 'matches')::int, 0) as "경기",
               coalesce((p.progress ->> 'wins')::int, 0) as "컴퓨터 상대 승",
               coalesce((p.progress ->> 'online')::int, 0) as "온라인",
               coalesce((p.progress ->> 'online_wins')::int, 0) as "온라인 승",
               coalesce((p.progress ->> 'sweet')::int, 0) as "딱",
               coalesce((p.progress ->> 'ranked')::int, 0) as "랭킹 등록",
               coalesce((p.progress ->> 'pulls')::int, 0) as "뽑기",
               p.tickets as "뽑기권",
               to_char(p.created_at at time zone 'Asia/Seoul', 'YY-MM-DD') as "가입",
               to_char((to_jsonb(p) ->> 'last_game_at')::timestamptz at time zone 'Asia/Seoul', 'MM-DD HH24:MI') as "마지막 경기 보상"
          from public.profiles p
         order by coalesce((p.progress ->> 'matches')::int, 0) desc
    $v$;
    revoke all on public.plays_members from anon, authenticated;
  end if;
end $$;
