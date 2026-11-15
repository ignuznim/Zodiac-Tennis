-- Zodiac Tennis: feedback and error reports from inside the game.
-- Run once in Supabase: SQL Editor -> New query -> paste -> Run. Safe to run again.
-- Anyone may send; nobody can read through the public key. Read them in the dashboard (Table Editor -> feedback).

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
