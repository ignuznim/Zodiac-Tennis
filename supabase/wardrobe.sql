-- Zodiac Tennis: accounts, the wardrobe, the gacha machine and achievements.
-- Run once in Supabase: SQL Editor -> New query -> paste -> Run. Safe to run again.
-- Everything that hands out items or tickets runs here, never in the browser.

-- ---- The item catalogue: four slots, four grades (0 일반, 1 희귀, 2 영웅, 3 전설) ----
create table if not exists public.items (
  id     text primary key,
  slot   text not null check (slot in ('hat', 'uniform', 'shoes', 'racket')),
  grade  smallint not null check (grade between 0 and 3),
  stat   text not null check (stat in ('power', 'stamina', 'spin', 'reflex', 'speed')),
  amount numeric(3, 2) not null,
  name   text not null
);
insert into public.items (id, slot, grade, stat, amount, name) values
  ('h1', 'hat', 0, 'reflex', 0.1, '흰 머리띠'),      ('h2', 'hat', 0, 'reflex', 0.1, '빨간 머리띠'),
  ('h3', 'hat', 1, 'reflex', 0.2, '파란 썬캡'),      ('h4', 'hat', 1, 'reflex', 0.2, '보라 머리띠'),
  ('h5', 'hat', 2, 'reflex', 0.3, '선비 갓'),        ('h6', 'hat', 3, 'reflex', 0.5, '황금 왕관'),
  ('u1', 'uniform', 0, 'stamina', 0.1, '흰 셔츠'),   ('u2', 'uniform', 0, 'stamina', 0.1, '하늘 셔츠'),
  ('u3', 'uniform', 1, 'stamina', 0.2, '줄무늬 셔츠'), ('u4', 'uniform', 1, 'stamina', 0.2, '국가대표 저지'),
  ('u5', 'uniform', 2, 'stamina', 0.3, '색동 한복'),  ('u6', 'uniform', 3, 'stamina', 0.5, '황금 유니폼'),
  ('s1', 'shoes', 0, 'speed', 0.1, '흰 운동화'),     ('s2', 'shoes', 0, 'speed', 0.1, '빨간 운동화'),
  ('s3', 'shoes', 1, 'speed', 0.2, '클레이화'),      ('s4', 'shoes', 1, 'speed', 0.2, '잔디화'),
  ('s5', 'shoes', 2, 'speed', 0.3, '번개 신발'),     ('s6', 'shoes', 3, 'speed', 0.5, '날개 신발'),
  ('r1', 'racket', 0, 'power', 0.1, '나무 라켓'),    ('r2', 'racket', 0, 'spin', 0.1, '연습 라켓'),
  ('r3', 'racket', 1, 'power', 0.2, '묵직한 라켓'),  ('r4', 'racket', 1, 'spin', 0.2, '가벼운 라켓'),
  ('r5', 'racket', 2, 'spin', 0.3, '용비늘 라켓'),   ('r6', 'racket', 3, 'power', 0.5, '황금 라켓')
on conflict (id) do update set slot = excluded.slot, grade = excluded.grade, stat = excluded.stat, amount = excluded.amount, name = excluded.name;

-- ---- Achievements: the reward in gacha tickets; a daily one can be claimed once a day ----
create table if not exists public.achievements (
  code   text primary key,
  reward smallint not null check (reward between 1 and 20),
  daily  boolean not null default false
);
insert into public.achievements (code, reward, daily) values
  ('daily', 1, true), ('first_win', 3, false), ('win_easy', 1, false), ('win_normal', 2, false), ('win_hard', 3, false),
  ('win_flash', 1, false), ('win_short', 2, false), ('win_regular', 5, false), ('lessons_all', 3, false),
  ('sweet_50', 2, false), ('sweet_300', 4, false), ('aces_10', 2, false), ('ranked', 1, false)
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

-- Put an item on (it must be owned and fit the slot), or take the slot off with null
create or replace function public.equip_item(s text, item text) returns public.profiles
language plpgsql security definer set search_path = public as $$
declare p public.profiles;
begin
  perform public.me();
  if s not in ('hat', 'uniform', 'shoes', 'racket') then raise exception 'bad slot'; end if;
  if item is null then
    update public.profiles set equip = equip - s where id = auth.uid() returning * into p;
  else
    if not exists (select 1 from public.inventory v join public.items i on i.id = v.item_id
                   where v.user_id = auth.uid() and v.item_id = item and i.slot = s) then raise exception 'not owned'; end if;
    update public.profiles set equip = equip || jsonb_build_object(s, item) where id = auth.uid() returning * into p;
  end if;
  return p;
end $$;

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

revoke all on function public.me(), public.set_nickname(text), public.gacha_pull(), public.equip_item(text, text),
  public.save_progress(jsonb), public.claim_achievement(text) from public, anon;
grant execute on function public.me(), public.set_nickname(text), public.gacha_pull(), public.equip_item(text, text),
  public.save_progress(jsonb), public.claim_achievement(text) to authenticated;

-- ---- The ranking shows what a player wore ----
alter table public.scores add column if not exists gear text check (gear is null or char_length(gear) <= 40);
grant select (gear) on public.scores to anon, authenticated;
grant insert (gear) on public.scores to anon, authenticated;
