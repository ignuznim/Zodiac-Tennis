-- 십이지 테니스 · 7. 라이벌과 프로필: head-to-head records from online matches, and a member's public profile. Needs 2 (profiles).
-- Run in Supabase: SQL Editor -> New query -> paste all of it -> Run.
-- Safe to run again: it only adds what is missing and replaces its own functions and rules; saved data stays.

-- ---- Head to head: each member keeps their own record against each member they meet online ----
create table if not exists public.rivals (
  user_id  uuid not null references auth.users (id) on delete cascade,
  opp_id   uuid not null references auth.users (id) on delete cascade,
  wins     integer not null default 0 check (wins >= 0),
  losses   integer not null default 0 check (losses >= 0),
  recent   text not null default '' check (char_length(recent) <= 5),  -- the last five, newest last: W or L
  last_at  timestamptz not null default now(),
  primary key (user_id, opp_id)
);
alter table public.rivals enable row level security;
revoke all on public.rivals from anon, authenticated;  -- read and written only through the functions below

-- After an online singles match: my result against that member. One a minute against the same opponent at most.
create or replace function public.record_rival(opp text, won boolean) returns jsonb
language plpgsql security definer set search_path = public as $$
declare oid uuid; r public.rivals;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select id into oid from public.profiles where nickname = btrim(opp);
  if oid is null or oid = auth.uid() then return null; end if;
  select * into r from public.rivals where user_id = auth.uid() and opp_id = oid;
  if found and r.last_at > now() - interval '60 seconds' then
    return jsonb_build_object('opp', btrim(opp), 'w', r.wins, 'l', r.losses, 'recent', r.recent);
  end if;
  insert into public.rivals (user_id, opp_id, wins, losses, recent, last_at)
    values (auth.uid(), oid, case when won then 1 else 0 end, case when won then 0 else 1 end, case when won then 'W' else 'L' end, now())
  on conflict (user_id, opp_id) do update set
    wins = public.rivals.wins + case when won then 1 else 0 end,
    losses = public.rivals.losses + case when won then 0 else 1 end,
    recent = right(public.rivals.recent || case when won then 'W' else 'L' end, 5),
    last_at = now()
  returning * into r;
  return jsonb_build_object('opp', btrim(opp), 'w', r.wins, 'l', r.losses, 'recent', r.recent);
end $$;

-- My three most-met rivals
create or replace function public.my_rivals() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x order by x.n desc, x.t desc), '[]'::jsonb) from (
    select p.nickname as nick, r.wins as w, r.losses as l, r.recent, r.wins + r.losses as n, r.last_at as t,
           (select key from jsonb_each(p.progress) where key like 'pa\_%' order by (value #>> '{}')::numeric desc limit 1) as fav
      from public.rivals r join public.profiles p on p.id = r.opp_id
     where r.user_id = auth.uid() and p.nickname is not null
     order by r.wins + r.losses desc, r.last_at desc limit 3) x;
$$;

-- ---- A member's profile, as anyone may see it: the nickname and the play counts, nothing about the account ----
create or replace function public.public_profile(nick text) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare p public.profiles; pr jsonb; r public.rivals;
begin
  select * into p from public.profiles where nickname = btrim(nick);
  if not found then return null; end if;
  select coalesce(jsonb_object_agg(key, value), '{}'::jsonb) into pr from jsonb_each(p.progress)
   where key in ('matches', 'wins', 'online', 'online_wins', 'rally', 'streak', 'sweet', 'aces', 'ranked', 'cpu_m', 'cpu_w')
      or key like 'pf\_%' or key like 'wf\_%' or key like 'pa\_%';
  if auth.uid() is not null and auth.uid() <> p.id then select * into r from public.rivals where user_id = auth.uid() and opp_id = p.id; end if;
  return jsonb_build_object('nickname', p.nickname, 'progress', pr, 'me', auth.uid() = p.id,
    'vs', case when r.user_id is null then null else jsonb_build_object('w', r.wins, 'l', r.losses, 'recent', r.recent) end);
end $$;

revoke all on function public.record_rival(text, boolean), public.my_rivals(), public.public_profile(text) from public, anon;
grant execute on function public.record_rival(text, boolean), public.my_rivals() to authenticated;
grant execute on function public.public_profile(text) to anon, authenticated;
