-- 십이지 테니스: everything the game keeps in Supabase, in one file.
-- Run in Supabase: SQL Editor -> New query -> paste all of it -> Run.
-- Safe to run again at any time: it only adds what is missing and replaces its own functions and rules;
-- no ranking record, item, ticket or achievement already saved is removed.
--
--   1. Ranking      the scores table (wins against the computer)
--   2. Wardrobe     items, achievements, profiles, inventory, the gacha machine, gear per animal
--   3. Feedback     notes from players and errors the game hits


-- ======================================================================
-- 1. Ranking
-- ======================================================================

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

-- One record per match: a double tap once sent the same win twice. Drop the repeats, keep the first,
-- and let the database refuse a repeat from now on (the game reads the refusal as "already sent").
delete from public.scores a using public.scores b
 where a.id > b.id and a.client_id = b.client_id and a.mode = b.mode and a.score = b.score
   and a.duration_s = b.duration_s and a.pts_for = b.pts_for and a.pts_against = b.pts_against;
create unique index if not exists scores_one_per_match on public.scores (client_id, mode, score, duration_s, pts_for, pts_against);


-- ======================================================================
-- 2. Wardrobe
-- ======================================================================

-- ---- The item catalogue: 100 items (27 hats, 25 uniforms, 24 shoes, 24 rackets), four grades (0 일반, 1 희귀, 2 영웅, 3 전설) ----
create table if not exists public.items (
  id     text primary key,
  slot   text not null check (slot in ('hat', 'uniform', 'shoes', 'racket')),
  grade  smallint not null check (grade between 0 and 3),
  stat   text not null check (stat in ('power', 'stamina', 'spin', 'reflex', 'speed')),
  amount numeric(3, 2) not null,
  name   text not null
);
insert into public.items (id, slot, grade, stat, amount, name) values
  ('h1', 'hat', 0, 'reflex', 0.1, '흰 머리띠'),
  ('h2', 'hat', 0, 'reflex', 0.1, '빨간 머리띠'),
  ('h7', 'hat', 0, 'speed', 0.1, '노란 머리띠'),
  ('h8', 'hat', 0, 'stamina', 0.1, '초록 머리띠'),
  ('h13', 'hat', 0, 'speed', 0.1, '하늘 머리띠'),
  ('h14', 'hat', 0, 'stamina', 0.1, '분홍 머리띠'),
  ('h15', 'hat', 0, 'power', 0.1, '검정 머리띠'),
  ('h3', 'hat', 1, 'reflex', 0.2, '파란 썬캡'),
  ('h4', 'hat', 1, 'spin', 0.2, '보라 머리띠'),
  ('h9', 'hat', 1, 'power', 0.2, '빨간 야구모자'),
  ('h10', 'hat', 1, 'speed', 0.2, '하얀 테니스캡'),
  ('h16', 'hat', 1, 'stamina', 0.2, '초록 야구모자'),
  ('h17', 'hat', 1, 'reflex', 0.2, '노란 썬바이저'),
  ('h18', 'hat', 1, 'speed', 0.2, '하늘 썬바이저'),
  ('h19', 'hat', 1, 'stamina', 0.2, '베이지 벙거지'),
  ('h20', 'hat', 1, 'spin', 0.2, '줄무늬 비니'),
  ('h5', 'hat', 2, 'reflex', 0.3, '선비 갓'),
  ('h11', 'hat', 2, 'stamina', 0.3, '족두리'),
  ('h21', 'hat', 2, 'spin', 0.3, '사모'),
  ('h22', 'hat', 2, 'reflex', 0.3, '꽃 화관'),
  ('h23', 'hat', 2, 'spin', 0.3, '마법사 모자'),
  ('h24', 'hat', 2, 'power', 0.3, '해적 모자'),
  ('h6', 'hat', 3, 'reflex', 0.5, '황금 왕관'),
  ('h12', 'hat', 3, 'power', 0.5, '은하수 왕관'),
  ('h25', 'hat', 3, 'speed', 0.5, '황금 캡'),
  ('h26', 'hat', 3, 'reflex', 0.5, '천사 고리'),
  ('h27', 'hat', 3, 'stamina', 0.5, '불꽃 왕관'),
  ('u1', 'uniform', 0, 'stamina', 0.1, '흰 티셔츠'),
  ('u2', 'uniform', 0, 'stamina', 0.1, '하늘 티셔츠'),
  ('u7', 'uniform', 0, 'reflex', 0.1, '분홍 티셔츠'),
  ('u8', 'uniform', 0, 'speed', 0.1, '민트 티셔츠'),
  ('u13', 'uniform', 0, 'power', 0.1, '노란 티셔츠'),
  ('u14', 'uniform', 0, 'spin', 0.1, '회색 티셔츠'),
  ('u15', 'uniform', 0, 'stamina', 0.1, '검정 티셔츠'),
  ('u3', 'uniform', 1, 'stamina', 0.2, '줄무늬 셔츠'),
  ('u4', 'uniform', 1, 'power', 0.2, '국가대표 저지'),
  ('u9', 'uniform', 1, 'spin', 0.2, '체크 셔츠'),
  ('u10', 'uniform', 1, 'reflex', 0.2, '해군 셔츠'),
  ('u16', 'uniform', 1, 'speed', 0.2, '초록 폴로 셔츠'),
  ('u17', 'uniform', 1, 'power', 0.2, '농구 민소매'),
  ('u18', 'uniform', 1, 'stamina', 0.2, '보라 후드티'),
  ('u19', 'uniform', 1, 'spin', 0.2, '노랑 저지'),
  ('u20', 'uniform', 1, 'reflex', 0.2, '하늘 줄무늬 셔츠'),
  ('u5', 'uniform', 2, 'stamina', 0.3, '색동 한복'),
  ('u11', 'uniform', 2, 'power', 0.3, '태권도 도복'),
  ('u21', 'uniform', 2, 'reflex', 0.3, '하늘 한복'),
  ('u22', 'uniform', 2, 'power', 0.3, '곤룡포'),
  ('u23', 'uniform', 2, 'speed', 0.3, '턱시도'),
  ('u6', 'uniform', 3, 'stamina', 0.5, '황금 유니폼'),
  ('u12', 'uniform', 3, 'power', 0.5, '불꽃 유니폼'),
  ('u24', 'uniform', 3, 'spin', 0.5, '무지개 유니폼'),
  ('u25', 'uniform', 3, 'reflex', 0.5, '은하수 유니폼'),
  ('s1', 'shoes', 0, 'speed', 0.1, '흰 운동화'),
  ('s2', 'shoes', 0, 'speed', 0.1, '빨간 운동화'),
  ('s7', 'shoes', 0, 'stamina', 0.1, '검정 운동화'),
  ('s8', 'shoes', 0, 'reflex', 0.1, '노란 운동화'),
  ('s13', 'shoes', 0, 'speed', 0.1, '하늘 운동화'),
  ('s14', 'shoes', 0, 'reflex', 0.1, '분홍 운동화'),
  ('s15', 'shoes', 0, 'stamina', 0.1, '초록 운동화'),
  ('s3', 'shoes', 1, 'speed', 0.2, '클레이화'),
  ('s4', 'shoes', 1, 'speed', 0.2, '잔디화'),
  ('s9', 'shoes', 1, 'stamina', 0.2, '하드코트화'),
  ('s10', 'shoes', 1, 'reflex', 0.2, '고무신'),
  ('s16', 'shoes', 1, 'speed', 0.2, '샌들'),
  ('s17', 'shoes', 1, 'stamina', 0.2, '노란 장화'),
  ('s18', 'shoes', 1, 'reflex', 0.2, '짚신'),
  ('s5', 'shoes', 2, 'speed', 0.3, '번개 신발'),
  ('s11', 'shoes', 2, 'stamina', 0.3, '꽃신'),
  ('s19', 'shoes', 2, 'power', 0.3, '나막신'),
  ('s20', 'shoes', 2, 'speed', 0.3, '롤러스케이트'),
  ('s21', 'shoes', 2, 'spin', 0.3, '피겨 스케이트'),
  ('s6', 'shoes', 3, 'speed', 0.5, '날개 신발'),
  ('s12', 'shoes', 3, 'power', 0.5, '로켓 신발'),
  ('s22', 'shoes', 3, 'speed', 0.5, '황금 운동화'),
  ('s23', 'shoes', 3, 'stamina', 0.5, '구름 신발'),
  ('s24', 'shoes', 3, 'spin', 0.5, '무지개 운동화'),
  ('r1', 'racket', 0, 'power', 0.1, '나무 라켓'),
  ('r2', 'racket', 0, 'spin', 0.1, '연습 라켓'),
  ('r7', 'racket', 0, 'reflex', 0.1, '하늘 라켓'),
  ('r8', 'racket', 0, 'speed', 0.1, '분홍 라켓'),
  ('r13', 'racket', 0, 'power', 0.1, '노란 라켓'),
  ('r14', 'racket', 0, 'stamina', 0.1, '초록 라켓'),
  ('r15', 'racket', 0, 'spin', 0.1, '보라 라켓'),
  ('r3', 'racket', 1, 'power', 0.2, '묵직한 라켓'),
  ('r4', 'racket', 1, 'spin', 0.2, '가벼운 라켓'),
  ('r9', 'racket', 1, 'stamina', 0.2, '대나무 라켓'),
  ('r10', 'racket', 1, 'reflex', 0.2, '얼음 라켓'),
  ('r16', 'racket', 1, 'power', 0.2, '카본 라켓'),
  ('r17', 'racket', 1, 'stamina', 0.2, '프라이팬'),
  ('r18', 'racket', 1, 'reflex', 0.2, '하트 라켓'),
  ('r5', 'racket', 2, 'spin', 0.3, '용비늘 라켓'),
  ('r11', 'racket', 2, 'power', 0.3, '태극 라켓'),
  ('r19', 'racket', 2, 'spin', 0.3, '태극 부채'),
  ('r20', 'racket', 2, 'reflex', 0.3, '별 라켓'),
  ('r21', 'racket', 2, 'speed', 0.3, '번개 라켓'),
  ('r22', 'racket', 2, 'stamina', 0.3, '꽃 라켓'),
  ('r6', 'racket', 3, 'power', 0.5, '황금 라켓'),
  ('r12', 'racket', 3, 'spin', 0.5, '무지개 라켓'),
  ('r23', 'racket', 3, 'spin', 0.5, '은하수 라켓'),
  ('r24', 'racket', 3, 'power', 0.5, '불꽃 라켓')
on conflict (id) do update set slot = excluded.slot, grade = excluded.grade, stat = excluded.stat, amount = excluded.amount, name = excluded.name;

-- ---- Achievements: the reward in gacha tickets; a daily one can be claimed once a day ----
create table if not exists public.achievements (
  code   text primary key,
  reward smallint not null check (reward between 1 and 20),
  daily  boolean not null default false
);
insert into public.achievements (code, reward, daily) values
  ('daily', 1, true), ('first_win', 1, false), ('win_easy', 1, false), ('win_normal', 1, false), ('win_hard', 2, false),
  ('win_flash', 1, false), ('win_short', 1, false), ('win_regular', 3, false), ('lessons_all', 2, false), ('ranked', 1, false),
  ('sweet_50', 1, false), ('aces_10', 1, false), ('wins_10', 2, false), ('sweet_300', 2, false), ('hard_5', 3, false),
  ('rally_30', 2, false), ('wins_50', 5, false), ('sweet_1000', 5, false), ('play_5', 1, false), ('play_20', 2, false),
  ('play_100', 4, false), ('wins_25', 3, false), ('wins_100', 6, false), ('hard_20', 5, false), ('court_hard', 1, false),
  ('court_grass', 1, false), ('court_clay', 1, false), ('animals_3', 1, false), ('animals_6', 2, false), ('animals_12', 5, false),
  ('power_50', 1, false), ('power_300', 2, false), ('aces_50', 2, false), ('aces_200', 4, false), ('sweet_3000', 5, false),
  ('rally_15', 1, false), ('rally_50', 3, false), ('online_1', 1, false), ('online_win', 2, false), ('online_10', 3, false),
  ('ranked_10', 2, false), ('pulls_10', 1, false), ('pulls_50', 3, false), ('own_10', 1, false), ('own_30', 2, false),
  ('own_60', 4, false), ('own_100', 10, false), ('legend_1', 2, false), ('full_set', 1, false)
on conflict (code) do update set reward = excluded.reward, daily = excluded.daily;

-- ---- One profile per account ----
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  nickname   text unique check (nickname is null or char_length(btrim(nickname)) between 1 and 10),
  tickets    integer not null default 3 check (tickets >= 0),
  equip      jsonb not null default '{}'::jsonb,
  progress   jsonb not null default '{}'::jsonb,
  claimed    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists public.inventory (
  user_id  uuid not null references auth.users (id) on delete cascade,
  item_id  text not null references public.items (id),
  count    integer not null default 1,
  first_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

alter table public.items enable row level security;
alter table public.achievements enable row level security;
alter table public.profiles enable row level security;
alter table public.inventory enable row level security;
drop policy if exists "read items" on public.items;
create policy "read items" on public.items for select to anon, authenticated using (true);
drop policy if exists "read achievements" on public.achievements;
create policy "read achievements" on public.achievements for select to anon, authenticated using (true);
drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "read own inventory" on public.inventory;
create policy "read own inventory" on public.inventory for select to authenticated using (user_id = auth.uid());
revoke all on public.items, public.achievements, public.profiles, public.inventory from anon, authenticated;
grant select on public.items, public.achievements to anon, authenticated;
grant select on public.profiles, public.inventory to authenticated;

-- ---- What the game may ask for: each checks who is asking ----
create or replace function public.me() returns public.profiles
language plpgsql security definer set search_path = public as $$
declare p public.profiles;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  insert into public.profiles (id) values (auth.uid()) on conflict (id) do nothing;
  select * into p from public.profiles where id = auth.uid();
  return p;
end $$;

create or replace function public.set_nickname(n text) returns public.profiles
language plpgsql security definer set search_path = public as $$
declare p public.profiles;
begin
  perform public.me();
  if char_length(btrim(n)) not between 1 and 10 then raise exception 'bad nickname'; end if;
  if exists (select 1 from public.profiles where nickname = btrim(n) and id <> auth.uid()) then raise exception 'nickname taken'; end if;
  update public.profiles set nickname = btrim(n) where id = auth.uid() returning * into p;
  return p;
end $$;

-- The machine: one ticket, a grade by its odds (56 / 28 / 12 / 4), then one item of that grade at random
create or replace function public.gacha_pull() returns jsonb
language plpgsql security definer set search_path = public as $$
declare r double precision; g smallint; it public.items; was integer;
begin
  perform public.me();
  update public.profiles set tickets = tickets - 1 where id = auth.uid() and tickets > 0;
  if not found then raise exception 'no tickets'; end if;
  r := random();
  g := case when r < 0.56 then 0 when r < 0.84 then 1 when r < 0.96 then 2 else 3 end;
  select * into it from public.items where grade = g order by random() limit 1;
  select count into was from public.inventory where user_id = auth.uid() and item_id = it.id;
  insert into public.inventory (user_id, item_id) values (auth.uid(), it.id)
    on conflict (user_id, item_id) do update set count = public.inventory.count + 1;
  return jsonb_build_object('item', it.id, 'grade', it.grade, 'new', was is null,
    'tickets', (select tickets from public.profiles where id = auth.uid()));
end $$;

-- Each animal (0-11) wears its own gear: equip is {"2": {"hat": "h5", ...}, ...}. One copy dresses one animal at a time:
-- if every copy owned is already worn by others, it is taken from one of them. A null item takes the slot off.
drop function if exists public.equip_item(text, text);
create or replace function public.equip_item(s text, item text, a integer) returns public.profiles
language plpgsql security definer set search_path = public as $$
declare p public.profiles; ak text := a::text; owned integer; worn integer; k text;
begin
  perform public.me();
  if s not in ('hat', 'uniform', 'shoes', 'racket') then raise exception 'bad slot'; end if;
  if a is null or a not between 0 and 11 then raise exception 'bad animal'; end if;
  select * into p from public.profiles where id = auth.uid();
  if item is null then
    p.equip := jsonb_set(p.equip, array[ak], coalesce(p.equip -> ak, '{}'::jsonb) - s, true);
  else
    select v.count into owned from public.inventory v join public.items i on i.id = v.item_id
      where v.user_id = auth.uid() and v.item_id = item and i.slot = s;
    if owned is null then raise exception 'not owned'; end if;
    select count(*) into worn from jsonb_each(p.equip) e where e.key <> ak and jsonb_typeof(e.value) = 'object' and e.value ->> s = item;
    if worn >= owned then
      select e.key into k from jsonb_each(p.equip) e where e.key <> ak and jsonb_typeof(e.value) = 'object' and e.value ->> s = item limit 1;
      p.equip := jsonb_set(p.equip, array[k], (p.equip -> k) - s);
    end if;
    p.equip := jsonb_set(p.equip, array[ak], coalesce(p.equip -> ak, '{}'::jsonb) || jsonb_build_object(s, item), true);
  end if;
  update public.profiles set equip = p.equip where id = auth.uid() returning * into p;
  return p;
end $$;
-- gear saved the old way (one set for everyone) moves to the rat (0); it can be moved from there
update public.profiles set equip = jsonb_build_object('0', equip) where equip ?| array['hat', 'uniform', 'shoes', 'racket'];

-- Progress kept with the account: each number only ever grows
create or replace function public.save_progress(pr jsonb) returns public.profiles
language plpgsql security definer set search_path = public as $$
declare p public.profiles; k text; v jsonb; cur jsonb;
begin
  perform public.me();
  select progress into cur from public.profiles where id = auth.uid();
  for k, v in select * from jsonb_each(coalesce(pr, '{}'::jsonb)) loop
    if jsonb_typeof(v) = 'number' and k ~ '^[a-z_]{1,24}$' then
      cur := cur || jsonb_build_object(k, greatest(coalesce((cur ->> k)::numeric, 0), least((v #>> '{}')::numeric, 1000000)));
    end if;
  end loop;
  update public.profiles set progress = cur where id = auth.uid() returning * into p;
  return p;
end $$;

-- An achievement's tickets, once (or once a day, by Korean time, for the daily one)
create or replace function public.claim_achievement(c text) returns public.profiles
language plpgsql security definer set search_path = public as $$
declare a public.achievements; p public.profiles; today text := to_char(now() at time zone 'Asia/Seoul', 'YYYY-MM-DD');
begin
  perform public.me();
  select * into a from public.achievements where code = c;
  if not found then raise exception 'no such achievement'; end if;
  select * into p from public.profiles where id = auth.uid();
  if a.daily and p.claimed ->> c = today then raise exception 'already claimed'; end if;
  if not a.daily and p.claimed ? c then raise exception 'already claimed'; end if;
  update public.profiles set tickets = tickets + a.reward,
    claimed = claimed || jsonb_build_object(c, case when a.daily then to_jsonb(today) else 'true'::jsonb end)
    where id = auth.uid() returning * into p;
  return p;
end $$;

revoke all on function public.me(), public.set_nickname(text), public.gacha_pull(), public.equip_item(text, text, integer),
  public.save_progress(jsonb), public.claim_achievement(text) from public, anon;
grant execute on function public.me(), public.set_nickname(text), public.gacha_pull(), public.equip_item(text, text, integer),
  public.save_progress(jsonb), public.claim_achievement(text) to authenticated;

-- ---- The ranking shows what a player wore ----
alter table public.scores add column if not exists gear text check (gear is null or char_length(gear) <= 40);
grant select (gear) on public.scores to anon, authenticated;
grant insert (gear) on public.scores to anon, authenticated;


-- ======================================================================
-- 3. Feedback
-- ======================================================================

create table if not exists public.feedback (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  kind       text not null check (kind in ('bug', 'ux', 'idea', 'error')),
  message    text not null check (char_length(message) between 1 and 1000),
  context    jsonb not null default '{}'::jsonb check (pg_column_size(context) < 4000),
  client_id  text check (client_id is null or char_length(client_id) <= 40),
  done       boolean not null default false  -- tick it in the dashboard once handled
);
create index if not exists feedback_recent on public.feedback (created_at desc);

-- A brake on floods: a few notes a minute and a handful of error reports an hour from one device
create or replace function public.feedback_limit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.client_id is not null then
    if new.kind <> 'error' and (select count(*) from public.feedback where client_id = new.client_id and kind <> 'error' and created_at > now() - interval '1 minute') >= 3 then
      raise exception 'too many';
    end if;
    if new.kind = 'error' and (select count(*) from public.feedback where client_id = new.client_id and kind = 'error' and created_at > now() - interval '1 hour') >= 20 then
      raise exception 'too many';
    end if;
  end if;
  new.done := false; new.created_at := now();
  return new;
end $$;
drop trigger if exists feedback_limit on public.feedback;
create trigger feedback_limit before insert on public.feedback for each row execute function public.feedback_limit();

alter table public.feedback enable row level security;
drop policy if exists "send feedback" on public.feedback;
create policy "send feedback" on public.feedback for insert to anon, authenticated with check (true);
revoke all on public.feedback from anon, authenticated;
grant insert (kind, message, context, client_id) on public.feedback to anon, authenticated;
