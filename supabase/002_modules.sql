-- Mtalii Bora — migration 2 (run AFTER schema.sql, in the Supabase SQL Editor).
-- Adds provider-set unavailable dates, message notifications, and tighter itinerary rules.
create table availability_blocks(id bigserial primary key, provider_id uuid not null references provider_profiles(id) on delete cascade,
  start_date date not null, end_date date not null check (end_date >= start_date), reason text default '', created_at timestamptz default now());
alter table availability_blocks enable row level security;
create policy "blocks read" on availability_blocks for select to authenticated using (true);
create policy "blocks own write" on availability_blocks for all to authenticated using (provider_id = auth.uid()) with check (provider_id = auth.uid());

create or replace function provider_busy(pid uuid) returns table(start_date date, end_date date) language sql stable security definer set search_path = public as $$
  select b.start_date, b.end_date from bookings b where b.provider_id = pid and b.status = 'accepted' and b.end_date >= current_date
  union all select a.start_date, a.end_date from availability_blocks a where a.provider_id = pid and a.end_date >= current_date $$;
create or replace function providers_busy_on(d date) returns setof uuid language sql stable security definer set search_path = public as $$
  select provider_id from bookings where status = 'accepted' and d between start_date and end_date
  union select provider_id from availability_blocks where d between start_date and end_date $$;

-- itinerary: only parties of an open booking may add items
drop policy "itinerary all" on itinerary_items;
create policy "itinerary read" on itinerary_items for select to authenticated using (is_party(booking_id));
create policy "itinerary add" on itinerary_items for insert to authenticated with check (is_party(booking_id) and exists(select 1 from bookings b where b.id = booking_id and b.status in ('pending','accepted','completed')));
create policy "itinerary delete" on itinerary_items for delete to authenticated using (is_party(booking_id));

-- notify the other person when a message arrives
create function on_message() returns trigger language plpgsql security definer set search_path = public as $$
declare b bookings;
begin select * into b from bookings where id = new.booking_id;
  insert into notifications(user_id, body, link) values (case when new.sender_id = b.traveler_id then b.provider_id else b.traveler_id end, 'New message on booking #' || b.id, '/bookings/' || b.id);
  return new; end $$;
create trigger message_after after insert on messages for each row execute function on_message();
