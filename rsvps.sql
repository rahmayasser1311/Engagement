-- Yasser & Rahma engagement: Supabase setup
-- Supabase: SQL Editor > New query > paste all > Run

create table if not exists rsvps (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name text not null check (char_length(name) between 1 and 100),
  attending text not null check (attending in ('yes', 'no')),
  guests int not null default 1 check (guests between 1 and 10),
  note text check (note is null or char_length(note) <= 500)
);

-- Guests can only ADD a reply. Nobody can read the table through the website.
alter table rsvps enable row level security;
drop policy if exists "guests can rsvp" on rsvps;
create policy "guests can rsvp" on rsvps
  for insert to anon
  with check (true);

-- Host login: the website sends the code, the DATABASE checks it.
-- The code is not written anywhere in the website file.
-- To change the code, edit 13112026 below and run again.
create or replace function get_rsvps(p_code text)
returns setof rsvps
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_code is distinct from '13112026' then
    perform pg_sleep(1);  -- slows down guessing
    raise exception 'wrong code';
  end if;
  return query select * from rsvps order by created_at desc;
end;
$$;

revoke all on function get_rsvps(text) from public;
grant execute on function get_rsvps(text) to anon;

-- Optional: replies already received on the Claude-hosted page
-- (delete these two lines if you do not want them)
insert into rsvps (created_at, name, attending, guests, note) values
  ('2026-10-23T20:27:45Z', 'Basmala', 'yes', 2, 'I love u mwah favorite bride'),
  ('2026-10-23T20:32:48Z', 'Molla',   'yes', 2, 'قبولاتي');
