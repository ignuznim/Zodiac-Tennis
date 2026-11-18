-- 십이지 테니스 · 2. 옷장: items, achievements, profiles, inventory, the gacha machine, gear per animal. Needs 1 (it adds the gear column to scores).
-- Run in Supabase: SQL Editor -> New query -> paste all of it -> Run.
-- Safe to run again: it only adds what is missing and replaces its own functions and rules; saved data stays.

-- ---- The item catalogue: 200 items (52 hats, 50 uniforms, 49 shoes, 49 rackets), four grades (0 일반, 1 희귀, 2 영웅, 3 전설) ----
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
  ('s1', 'shoes', 0, 'speed', 0.1, '흰 테니스화'),
  ('s2', 'shoes', 0, 'speed', 0.1, '빨간 러닝화'),
  ('s7', 'shoes', 0, 'stamina', 0.1, '검정 슬립온'),
  ('s8', 'shoes', 0, 'reflex', 0.1, '노란 찍찍이 운동화'),
  ('s13', 'shoes', 0, 'speed', 0.1, '하늘 캔버스화'),
  ('s14', 'shoes', 0, 'reflex', 0.1, '분홍 캔버스화'),
  ('s15', 'shoes', 0, 'stamina', 0.1, '초록 러닝화'),
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
  ('s21', 'shoes', 2, 'spin', 0.3, '스케이트화'),
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
  ('r24', 'racket', 3, 'power', 0.5, '불꽃 라켓'),
  ('h28', 'hat', 0, 'power', 0.1, '주황 머리띠'),
  ('h29', 'hat', 0, 'spin', 0.1, '민트 머리띠'),
  ('h30', 'hat', 0, 'stamina', 0.1, '남색 머리띠'),
  ('h31', 'hat', 0, 'reflex', 0.1, '땡땡이 두건'),
  ('h32', 'hat', 0, 'stamina', 0.1, '이태리타월 머리띠'),
  ('h33', 'hat', 0, 'speed', 0.1, '볼보이 캡'),
  ('h34', 'hat', 0, 'spin', 0.1, '신문지 고깔'),
  ('h35', 'hat', 1, 'reflex', 0.2, '고무장갑 모자'),
  ('h36', 'hat', 1, 'stamina', 0.2, '냄비 모자'),
  ('h37', 'hat', 1, 'spin', 0.2, '양머리 수건'),
  ('h38', 'hat', 1, 'speed', 0.2, '해녀 물안경'),
  ('h39', 'hat', 1, 'reflex', 0.2, '흰 테 고글'),
  ('h40', 'hat', 1, 'power', 0.2, '유건'),
  ('h41', 'hat', 1, 'speed', 0.2, '70년대 굵은 머리띠'),
  ('h42', 'hat', 1, 'power', 0.2, '황제 헤어밴드'),
  ('h43', 'hat', 2, 'spin', 0.3, '상모'),
  ('h44', 'hat', 2, 'reflex', 0.3, '하회탈'),
  ('h45', 'hat', 2, 'speed', 0.3, '대나무 프로펠러'),
  ('h46', 'hat', 2, 'stamina', 0.3, '비행 고글 모자'),
  ('h47', 'hat', 2, 'spin', 0.3, '커다란 빨간 리본'),
  ('h48', 'hat', 2, 'power', 0.3, '국가대표 야구모자'),
  ('h49', 'hat', 3, 'stamina', 0.5, '신라 금관'),
  ('h50', 'hat', 3, 'power', 0.5, '우승 트로피 모자'),
  ('h51', 'hat', 3, 'reflex', 0.5, '긴고아'),
  ('h52', 'hat', 3, 'speed', 0.5, '나뭇잎 우산'),
  ('u26', 'uniform', 0, 'power', 0.1, '빨간 티셔츠'),
  ('u27', 'uniform', 0, 'stamina', 0.1, '남색 티셔츠'),
  ('u28', 'uniform', 0, 'speed', 0.1, '연두 티셔츠'),
  ('u29', 'uniform', 0, 'spin', 0.1, '보라 티셔츠'),
  ('u30', 'uniform', 0, 'reflex', 0.1, '베이지 티셔츠'),
  ('u31', 'uniform', 0, 'spin', 0.1, '흙투성이 흰 셔츠'),
  ('u32', 'uniform', 0, 'speed', 0.1, '난닝구'),
  ('u33', 'uniform', 1, 'stamina', 0.2, '찜질방 옷'),
  ('u34', 'uniform', 1, 'power', 0.2, '꽃무늬 몸빼바지'),
  ('u35', 'uniform', 1, 'reflex', 0.2, '파자마'),
  ('u36', 'uniform', 1, 'speed', 0.2, '유생복'),
  ('u37', 'uniform', 2, 'power', 0.3, '황룡포'),
  ('u38', 'uniform', 1, 'spin', 0.2, '70년대 줄무늬 폴로'),
  ('u39', 'uniform', 1, 'spin', 0.2, '볼보이 유니폼'),
  ('u40', 'uniform', 1, 'reflex', 0.2, '심판 블레이저'),
  ('u41', 'uniform', 2, 'stamina', 0.3, '황제 카디건'),
  ('u42', 'uniform', 2, 'spin', 0.3, '발레복'),
  ('u43', 'uniform', 2, 'power', 0.3, '농악복'),
  ('u44', 'uniform', 2, 'reflex', 0.3, '선비 도포'),
  ('u45', 'uniform', 2, 'speed', 0.3, '얼음 드레스'),
  ('u46', 'uniform', 2, 'stamina', 0.3, '교복'),
  ('u47', 'uniform', 3, 'power', 0.5, '화랑 무복'),
  ('u48', 'uniform', 3, 'reflex', 0.5, '윔블던 올화이트'),
  ('u49', 'uniform', 3, 'speed', 0.5, '검은 캣슈트'),
  ('u50', 'uniform', 3, 'stamina', 0.5, '국가대표 야구 유니폼'),
  ('s25', 'shoes', 0, 'speed', 0.1, '주황 캔버스화'),
  ('s26', 'shoes', 0, 'stamina', 0.1, '남색 테니스화'),
  ('s27', 'shoes', 0, 'reflex', 0.1, '연두 찍찍이 운동화'),
  ('s28', 'shoes', 0, 'spin', 0.1, '보라 어글리 슈즈'),
  ('s29', 'shoes', 0, 'power', 0.1, '회색 슬립온'),
  ('s30', 'shoes', 0, 'speed', 0.1, '민트 하이탑'),
  ('s31', 'shoes', 0, 'reflex', 0.1, '흙 묻은 운동화'),
  ('s32', 'shoes', 1, 'speed', 0.2, '삼선 슬리퍼'),
  ('s33', 'shoes', 1, 'stamina', 0.2, '곰발바닥 슬리퍼'),
  ('s34', 'shoes', 1, 'power', 0.2, '오리발'),
  ('s35', 'shoes', 1, 'reflex', 0.2, '양말에 샌들'),
  ('s36', 'shoes', 1, 'spin', 0.2, '실내화'),
  ('s37', 'shoes', 1, 'spin', 0.2, '테니스공 신발'),
  ('s38', 'shoes', 1, 'power', 0.2, '빨간 하이탑'),
  ('s39', 'shoes', 1, 'stamina', 0.2, '털부츠'),
  ('s40', 'shoes', 2, 'reflex', 0.3, '태사혜'),
  ('s41', 'shoes', 2, 'spin', 0.3, '버선'),
  ('s42', 'shoes', 2, 'speed', 0.3, '빨간 반짝 구두'),
  ('s43', 'shoes', 2, 'power', 0.3, '스프링 신발'),
  ('s44', 'shoes', 2, 'reflex', 0.3, '잔디 운동화'),
  ('s45', 'shoes', 2, 'stamina', 0.3, '개구리 장화'),
  ('s46', 'shoes', 3, 'speed', 0.5, '유리구두'),
  ('s47', 'shoes', 3, 'stamina', 0.5, '황금 고무신'),
  ('s48', 'shoes', 3, 'spin', 0.5, '은하수 운동화'),
  ('s49', 'shoes', 3, 'power', 0.5, '불꽃 운동화'),
  ('r25', 'racket', 0, 'speed', 0.1, '주황 라켓'),
  ('r26', 'racket', 0, 'stamina', 0.1, '남색 라켓'),
  ('r27', 'racket', 0, 'power', 0.1, '빨간 라켓'),
  ('r28', 'racket', 0, 'reflex', 0.1, '민트 라켓'),
  ('r29', 'racket', 0, 'spin', 0.1, '회색 라켓'),
  ('r30', 'racket', 0, 'power', 0.1, '부러진 라켓'),
  ('r31', 'racket', 0, 'stamina', 0.1, '테이프 감은 라켓'),
  ('r32', 'racket', 1, 'power', 0.2, '대파'),
  ('r33', 'racket', 1, 'reflex', 0.2, '효자손'),
  ('r34', 'racket', 1, 'stamina', 0.2, '뿅망치'),
  ('r35', 'racket', 1, 'speed', 0.2, '파리채'),
  ('r36', 'racket', 1, 'spin', 0.2, '국자'),
  ('r37', 'racket', 1, 'spin', 0.2, '바나나'),
  ('r38', 'racket', 1, 'speed', 0.2, '마법사 빗자루'),
  ('r39', 'racket', 1, 'stamina', 0.2, '떡꼬치'),
  ('r40', 'racket', 2, 'power', 0.3, '소고'),
  ('r41', 'racket', 2, 'reflex', 0.3, '합죽선'),
  ('r42', 'racket', 2, 'stamina', 0.3, '붕어빵 라켓'),
  ('r43', 'racket', 2, 'reflex', 0.3, '우승 은쟁반'),
  ('r44', 'racket', 2, 'spin', 0.3, '요술봉'),
  ('r45', 'racket', 2, 'speed', 0.3, '파초선'),
  ('r46', 'racket', 3, 'spin', 0.5, '야구 방망이'),
  ('r47', 'racket', 3, 'power', 0.5, '황금 대파'),
  ('r48', 'racket', 3, 'speed', 0.5, '광선검'),
  ('r49', 'racket', 3, 'reflex', 0.5, '여의봉')
on conflict (id) do update set slot = excluded.slot, grade = excluded.grade, stat = excluded.stat, amount = excluded.amount, name = excluded.name;

-- ---- Achievements: the reward in gacha tickets; a daily one can be claimed once a day ----
create table if not exists public.achievements (
  code   text primary key,
  reward smallint not null check (reward between 1 and 20),
  daily  boolean not null default false
);
alter table public.achievements add column if not exists weekly boolean not null default false; -- claimed once a week (Monday to Sunday, Korean time)
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
  ('own_60', 4, false), ('own_100', 10, false), ('own_150', 12, false), ('own_200', 20, false), ('legend_1', 2, false), ('full_set', 1, false),
  ('d_play', 1, true), ('d_win', 1, true), ('d_sweet', 1, true),
  ('play_1', 1, false), ('pulls_1', 1, false), ('equip_1', 1, false), ('sweet_10', 1, false), ('power_10', 1, false),
  ('rally_10', 1, false), ('aces_1', 1, false), ('win_doubles', 1, false), ('own_5', 1, false),
  ('d_play3', 3, true), ('d_win2', 2, true), ('d_power', 1, true), ('d_night', 2, true)
on conflict (code) do update set reward = excluded.reward, daily = excluded.daily;
-- this week's: twenty tickets a week on top of the daily ten
insert into public.achievements (code, reward, daily, weekly) values
  ('w_wins', 7, false, true), ('w_animals', 5, false, true), ('w_sweet', 4, false, true), ('w_days', 4, false, true)
on conflict (code) do update set reward = excluded.reward, daily = excluded.daily, weekly = excluded.weekly;

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
  if char_length(btrim(n)) not between 1 and 8 then raise exception 'bad nickname'; end if; -- new names up to 8; older ones up to 10 stay
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
  select * into it from public.items where grade = g order by random() limit 1; -- every item of the grade equally likely, owned or not
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
  week text := to_char(date_trunc('week', now() at time zone 'Asia/Seoul'), 'YYYY-MM-DD'); -- the Monday of this week
begin
  perform public.me();
  select * into a from public.achievements where code = c;
  if not found then raise exception 'no such achievement'; end if;
  select * into p from public.profiles where id = auth.uid();
  if a.weekly and p.claimed ->> c = week then raise exception 'already claimed'; end if;
  if a.daily and p.claimed ->> c = today then raise exception 'already claimed'; end if;
  if not a.daily and not a.weekly and p.claimed ? c then raise exception 'already claimed'; end if;
  update public.profiles set tickets = tickets + a.reward,
    claimed = claimed || jsonb_build_object(c, case when a.weekly then to_jsonb(week) when a.daily then to_jsonb(today) else 'true'::jsonb end)
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
