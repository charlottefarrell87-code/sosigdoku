-- Sosigdoku leaderboard setup
-- Paste this whole file into Supabase > SQL Editor > New query, then press Run.

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 20),
  key text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.plays (
  player_id uuid not null references public.players(id) on delete cascade,
  day date not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  ms integer,
  mistakes integer,
  score integer,
  primary key (player_id, day)
);

-- Lock the tables down: the site can read scores and names, and can only write through the functions below.
alter table public.players enable row level security;
alter table public.plays enable row level security;

drop policy if exists "Scores are public" on public.plays;
create policy "Scores are public" on public.plays for select to anon, authenticated using (true);
grant select on public.plays to anon, authenticated;
revoke all on public.players from anon, authenticated;

-- Names only (player codes stay private)
create or replace view public.player_names as select id, name from public.players;
grant select on public.player_names to anon, authenticated;

-- Join: creates a player and returns their 8-character code
create or replace function public.join_league(p_name text)
returns table (player_id uuid, player_name text, player_key text)
language plpgsql security definer set search_path = public as $$
declare
  k text;
  alphabet text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  i int;
begin
  p_name := btrim(p_name);
  if char_length(p_name) < 1 or char_length(p_name) > 20 then
    raise exception 'Name must be 1 to 20 characters';
  end if;
  loop
    k := '';
    for i in 1..8 loop
      k := k || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from players p where p.key = k);
  end loop;
  return query insert into players (name, key) values (p_name, k)
    returning players.id, players.name, players.key;
end $$;

-- Sign in on another device with a player code
create or replace function public.sign_in(p_key text)
returns table (player_id uuid, player_name text)
language sql security definer set search_path = public as $$
  select p.id, p.name from players p where p.key = upper(regexp_replace(p_key, '[^A-Za-z0-9]', '', 'g'));
$$;

create or replace function public.rename_player(p_key text, p_name text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  p_name := btrim(p_name);
  if char_length(p_name) < 1 or char_length(p_name) > 20 then
    raise exception 'Name must be 1 to 20 characters';
  end if;
  update players set name = p_name where key = p_key;
  if not found then raise exception 'Unknown player'; end if;
end $$;

-- Starts the clock for a puzzle (server time). Only today and earlier puzzles can be played.
create or replace function public.start_play(p_key text, p_day date)
returns timestamptz
language plpgsql security definer set search_path = public as $$
declare
  pid uuid;
  st timestamptz;
  today date := (now() at time zone 'Europe/London')::date;
begin
  select id into pid from players where key = p_key;
  if pid is null then raise exception 'Unknown player'; end if;
  if p_day > today or p_day < date '2026-10-01' then raise exception 'That puzzle is not available'; end if;
  insert into plays (player_id, day) values (pid, p_day) on conflict do nothing;
  select pl.started_at into st from plays pl where pl.player_id = pid and pl.day = p_day;
  return st;
end $$;

-- Finishes a puzzle once. Time is measured by the server (never less than the time the device reports).
create or replace function public.finish_play(p_key text, p_day date, p_mistakes int, p_client_ms int default 0)
returns table (out_ms int, out_mistakes int, out_score int)
language plpgsql security definer set search_path = public as $$
declare
  pid uuid;
  elapsed int;
begin
  select id into pid from players where key = p_key;
  if pid is null then raise exception 'Unknown player'; end if;
  select greatest((extract(epoch from now() - pl.started_at) * 1000)::int, coalesce(p_client_ms, 0))
    into elapsed from plays pl where pl.player_id = pid and pl.day = p_day and pl.finished_at is null;
  if elapsed is not null then
    update plays set finished_at = now(), ms = elapsed, mistakes = greatest(0, p_mistakes),
      score = elapsed + greatest(0, p_mistakes) * 30000
    where player_id = pid and day = p_day;
  end if;
  return query select pl.ms, pl.mistakes, pl.score from plays pl where pl.player_id = pid and pl.day = p_day;
end $$;

grant execute on function public.join_league(text), public.sign_in(text), public.rename_player(text, text),
  public.start_play(text, date), public.finish_play(text, date, int, int) to anon, authenticated;
