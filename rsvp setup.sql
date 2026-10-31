-- RSVP setup for the invitation (run in Supabase: SQL Editor -> New query -> Run)
-- Safe to run more than once.

-- 1) RSVP table ---------------------------------------------------------
create table if not exists public.rsvps (
  id          bigint generated always as identity primary key,
  name        text        not null,
  attending   text        not null check (attending in ('yes', 'no')),
  guests      integer     not null default 1 check (guests between 1 and 10),
  note        text,
  created_at  timestamptz not null default now()
);

alter table public.rsvps enable row level security;

-- Guests (anon key) may only ADD a reply. They can never read the list.
drop policy if exists "anyone can submit rsvp" on public.rsvps;
create policy "anyone can submit rsvp"
  on public.rsvps
  for insert
  to anon
  with check (true);

revoke all on public.rsvps from anon;
grant insert on public.rsvps to anon;

-- 2) Host code ----------------------------------------------------------
-- The code you type under "Host login" on the page.
-- >>> CHANGE 'CHANGE_ME' to your own code before running. <<<
create table if not exists public.rsvp_settings (
  id        integer primary key default 1 check (id = 1),
  host_code text not null
);

alter table public.rsvp_settings enable row level security;   -- no policies = nobody but the server can read it
revoke all on public.rsvp_settings from anon, authenticated;

insert into public.rsvp_settings (id, host_code)
values (1, 'CHANGE_ME')
on conflict (id) do update set host_code = excluded.host_code;

-- 3) Guest list function (called by the page as rpc/get_rsvps) ----------
create or replace function public.get_rsvps(p_code text)
returns table (
  name       text,
  attending  text,
  guests     integer,
  note       text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.rsvp_settings s where s.id = 1 and s.host_code = p_code
  ) then
    raise exception 'wrong code' using errcode = '28000';
  end if;

  return query
    select r.name, r.attending, r.guests, r.note, r.created_at
    from public.rsvps r
    order by r.created_at desc;
end;
$$;

revoke all on function public.get_rsvps(text) from public;
grant execute on function public.get_rsvps(text) to anon;

-- To change the host code later:
--   update public.rsvp_settings set host_code = 'NEW_CODE' where id = 1;
