-- 십이지 테니스 · 8. 티어 (조선 품계): each member's skill score and days played, and the board. Needs 2 (profiles).
-- Run in Supabase: SQL Editor -> New query -> paste all of it -> Run.
-- Safe to run again: it only adds what is missing and replaces its own functions and rules; saved data stays.
--
-- The score is an Elo rating: everyone starts at 1,000; a win against a stronger side earns more, a loss to a weaker side costs more,
-- so the score settles where a player's results put it and playing more alone never lifts it. The computer is 1,000 / 1,300 / 1,600
-- by level; an online singles opponent who is a member counts at their own score. No seasons: it carries on.
-- The game turns score, days played and place into the tier (양인·천민 by score, 9품~3품 by score and days, 2품·1품·왕 by place).

create table if not exists public.ratings (
  user_id  uuid primary key references auth.users (id) on delete cascade,
  rating   integer not null default 1000 check (rating between 0 and 4000),
  games    integer not null default 0,
  days     integer not null default 0,                  -- days with at least one finished match (Korean days)
  last_day text,
  last_at  timestamptz,
  best     integer not null default 1000
);
create index if not exists ratings_rank on public.ratings (rating desc);
alter table public.ratings enable row level security;
revoke all on public.ratings from anon, authenticated;  -- read and written only through the functions below

-- 3품 and above: the ones who may hold 2품, 1품 and 왕 by place
create or replace function public.tier_rank(uid uuid) returns integer
language sql stable security definer set search_path = public as $$
  select case when r.rating >= 1630 and r.days >= 40
    then 1 + (select count(*) from public.ratings o where o.rating >= 1630 and o.days >= 40 and (o.rating > r.rating or (o.rating = r.rating and o.last_at < r.last_at)))
    else null end
  from public.ratings r where r.user_id = uid;
$$;

-- After a finished match. fmt: flash / short / regular; level: the computer's, or null online; opp: an online singles opponent's nickname.
-- At most one result per real match's length, like the ticket reward.
create or replace function public.tier_match(fmt text, level integer, won boolean, opp text default null) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me public.ratings; oid uuid; orating integer; k numeric; e numeric; d integer; gap integer;
  today text := to_char(now() at time zone 'Asia/Seoul', 'YYYY-MM-DD');
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  k := case fmt when 'flash' then 16 when 'short' then 24 when 'regular' then 40 end;
  gap := case fmt when 'flash' then 90 when 'short' then 150 when 'regular' then 420 end;
  if k is null then raise exception 'bad format'; end if;
  insert into public.ratings (user_id) values (auth.uid()) on conflict (user_id) do nothing;
  select * into me from public.ratings where user_id = auth.uid() for update;
  if me.last_at is not null and now() - me.last_at < make_interval(secs => gap) then raise exception 'too soon'; end if;
  if opp is not null then
    select id into oid from public.profiles where nickname = btrim(opp);
    if oid is null or oid = auth.uid() then raise exception 'no opponent'; end if;
    insert into public.ratings (user_id) values (oid) on conflict (user_id) do nothing;
    select rating into orating from public.ratings where user_id = oid;
  else
    orating := case level when 1 then 1000 when 2 then 1300 when 3 then 1600 end;
    if orating is null then raise exception 'bad level'; end if;
  end if;
  e := 1 / (1 + power(10, (orating - me.rating) / 400.0));
  d := round(k * ((case when won then 1 else 0 end) - e));
  update public.ratings set rating = greatest(0, me.rating + d), games = me.games + 1,
      days = me.days + case when me.last_day is distinct from today then 1 else 0 end, last_day = today, last_at = now(),
      best = greatest(me.best, me.rating + d)
    where user_id = auth.uid() returning * into me;
  return jsonb_build_object('rating', me.rating, 'delta', d, 'days', me.days, 'games', me.games, 'rank', public.tier_rank(auth.uid()));
end $$;

-- My score now (zeros if I have not played since the tiers began)
create or replace function public.my_tier() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce((select jsonb_build_object('rating', r.rating, 'days', r.days, 'games', r.games, 'best', r.best, 'rank', public.tier_rank(r.user_id))
    from public.ratings r where r.user_id = auth.uid()), jsonb_build_object('rating', 1000, 'days', 0, 'games', 0, 'best', 1000, 'rank', null));
$$;

-- A member's score, by nickname (for their profile)
create or replace function public.tier_of(nick text) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce((select jsonb_build_object('rating', r.rating, 'days', r.days, 'games', r.games, 'best', r.best, 'rank', public.tier_rank(r.user_id))
    from public.profiles p join public.ratings r on r.user_id = p.id where p.nickname = btrim(nick)),
    jsonb_build_object('rating', 1000, 'days', 0, 'games', 0, 'best', 1000, 'rank', null));
$$;

-- The board: every member who has played, by score, with the animal each plays most
create or replace function public.tier_board(lim integer default 50) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x order by x.rating desc, x.t asc), '[]'::jsonb) from (
    select p.nickname as nick, r.rating, r.days, r.games, r.last_at as t, public.tier_rank(r.user_id) as rank,
           (select key from jsonb_each(p.progress) where key like 'pa\_%' order by (value #>> '{}')::numeric desc limit 1) as fav
      from public.ratings r join public.profiles p on p.id = r.user_id
     where p.nickname is not null and r.games > 0
     order by r.rating desc, r.last_at asc limit least(greatest(lim, 1), 5000)) x;
$$;

revoke all on function public.tier_rank(uuid), public.tier_match(text, integer, boolean, text), public.my_tier(), public.tier_of(text), public.tier_board(integer) from public, anon;
grant execute on function public.tier_match(text, integer, boolean, text), public.my_tier() to authenticated;
grant execute on function public.tier_of(text), public.tier_board(integer) to anon, authenticated;
