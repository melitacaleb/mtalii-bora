-- Mtalii Bora — Supabase schema. Run once in: Supabase Dashboard > SQL Editor > New query.
create extension if not exists btree_gist;
create type user_role as enum ('traveler','guide','driver','admin');
create type booking_status as enum ('pending','accepted','rejected','completed','cancelled');

create table profiles(id uuid primary key references auth.users(id) on delete cascade, full_name text not null, role user_role not null default 'traveler', created_at timestamptz default now());
create table provider_profiles(id uuid primary key references profiles(id) on delete cascade, type text not null check (type in ('guide','driver')),
  bio text default '', county text default '', languages text default '', rate_usd int default 0 check (rate_usd >= 0), vehicle text default '', license_no text default '',
  services text[] default '{}', verified boolean default false, rating_avg numeric(2,1) default 0, rating_count int default 0);
create table destinations(id serial primary key, name text not null, county text not null, category text not null, description text, activities text, wiki_title text);
create table bookings(id bigserial primary key, traveler_id uuid not null references profiles(id), provider_id uuid not null references provider_profiles(id),
  start_date date not null, end_date date not null, travelers int default 1 check (travelers > 0), note text default '', status booking_status default 'pending', created_at timestamptz default now(),
  check (end_date >= start_date),
  exclude using gist (provider_id with =, daterange(start_date, end_date, '[]') with &&) where (status = 'accepted'));
create table messages(id bigserial primary key, booking_id bigint references bookings(id) on delete cascade, sender_id uuid references profiles(id), body text not null check (length(body) <= 1000), created_at timestamptz default now());
create table itinerary_items(id bigserial primary key, booking_id bigint references bookings(id) on delete cascade, day int not null default 1, start_time time, title text not null, destination_id int references destinations(id), notes text default '');
create table reviews(id bigserial primary key, booking_id bigint unique references bookings(id), provider_id uuid references provider_profiles(id), rating int not null check (rating between 1 and 5), comment text default '', created_at timestamptz default now());
create table notifications(id bigserial primary key, user_id uuid references profiles(id) on delete cascade, body text not null, link text, read boolean default false, created_at timestamptz default now());
create table audit_log(id bigserial primary key, user_id uuid, action text not null, detail text, created_at timestamptz default now());

-- helpers
create function is_admin() returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from profiles where id = auth.uid() and role = 'admin') $$;
create function is_party(b bigint) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from bookings where id = b and (traveler_id = auth.uid() or provider_id = auth.uid())) $$;
create function provider_busy(pid uuid) returns table(start_date date, end_date date) language sql stable security definer set search_path = public as $$ select start_date, end_date from bookings where provider_id = pid and status = 'accepted' and end_date >= current_date $$;
create function providers_busy_on(d date) returns setof uuid language sql stable security definer set search_path = public as $$ select provider_id from bookings where status = 'accepted' and d between start_date and end_date $$;
create function set_verified(pid uuid, v boolean) returns void language plpgsql security definer set search_path = public as $$
begin if not is_admin() then raise exception 'Admin only'; end if;
  update provider_profiles set verified = v where id = pid; insert into audit_log(user_id, action, detail) values (auth.uid(), 'provider_verify', pid || '=' || v); end $$;
revoke execute on function provider_busy, providers_busy_on, set_verified from public, anon;
grant execute on function provider_busy, providers_busy_on, set_verified to authenticated;

-- new auth user -> profile (+ provider profile). Role comes from sign-up metadata; 'admin' can never be self-assigned.
create function handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
declare m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
        r user_role := case when m->>'role' in ('guide','driver') then (m->>'role')::user_role else 'traveler' end;
begin
  insert into profiles(id, full_name, role) values (new.id, coalesce(nullif(m->>'full_name',''), split_part(new.email,'@',1)), r);
  if r in ('guide','driver') then
    insert into provider_profiles(id, type, bio, county, languages, rate_usd, vehicle, license_no, services)
    values (new.id, r::text, coalesce(m->>'bio',''), coalesce(m->>'county',''), coalesce(m->>'languages',''), coalesce(nullif(m->>'rate','')::int, 0),
            coalesce(m->>'vehicle',''), coalesce(m->>'license_no',''), string_to_array(nullif(m->>'services',''), ','));
  end if;
  insert into audit_log(user_id, action, detail) values (new.id, 'register', r::text);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

-- booking rules: who may change status, notifications and audit trail
create function check_booking() returns trigger language plpgsql as $$
begin
  if new.status <> old.status and auth.uid() is not null and not is_admin() then
    if auth.uid() = old.provider_id and ((old.status = 'pending' and new.status in ('accepted','rejected')) or (old.status = 'accepted' and new.status = 'completed')) then null;
    elsif auth.uid() = old.traveler_id and old.status in ('pending','accepted') and new.status = 'cancelled' then null;
    else raise exception 'This status change is not allowed'; end if;
  end if; return new;
end $$;
create trigger booking_guard before update on bookings for each row execute function check_booking();
create function on_booking_change() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    insert into notifications(user_id, body, link) values (new.provider_id, 'New booking request #' || new.id, '/bookings');
    insert into audit_log(user_id, action, detail) values (new.traveler_id, 'booking_create', '#' || new.id);
  elsif new.status <> old.status then
    insert into notifications(user_id, body, link) values (case when auth.uid() = new.provider_id then new.traveler_id else new.provider_id end, 'Booking #' || new.id || ' is now ' || new.status, '/bookings');
    insert into audit_log(user_id, action, detail) values (auth.uid(), 'booking_' || new.status, '#' || new.id);
  end if; return new;
end $$;
create trigger booking_after after insert or update on bookings for each row execute function on_booking_change();
create function reset_verified() returns trigger language plpgsql security definer set search_path = public as $$
begin if new.license_no is distinct from old.license_no and not is_admin() then new.verified := false; end if; return new; end $$;
create trigger provider_license before update on provider_profiles for each row execute function reset_verified();
create function update_rating() returns trigger language plpgsql security definer set search_path = public as $$
begin update provider_profiles set rating_avg = (select round(avg(rating), 1) from reviews where provider_id = new.provider_id), rating_count = (select count(*) from reviews where provider_id = new.provider_id) where id = new.provider_id; return new; end $$;
create trigger review_after after insert on reviews for each row execute function update_rating();

-- row level security
alter table profiles enable row level security; alter table provider_profiles enable row level security; alter table destinations enable row level security;
alter table bookings enable row level security; alter table messages enable row level security; alter table itinerary_items enable row level security;
alter table reviews enable row level security; alter table notifications enable row level security; alter table audit_log enable row level security;
create policy "profiles read" on profiles for select to authenticated using (true);
create policy "profiles update own" on profiles for update to authenticated using (id = auth.uid());
create policy "providers read" on provider_profiles for select to authenticated using (true);
create policy "providers update own" on provider_profiles for update to authenticated using (id = auth.uid());
create policy "destinations read" on destinations for select to anon, authenticated using (true);
create policy "destinations admin" on destinations for all to authenticated using (is_admin()) with check (is_admin());
create policy "bookings read" on bookings for select to authenticated using (traveler_id = auth.uid() or provider_id = auth.uid() or is_admin());
create policy "bookings insert" on bookings for insert to authenticated with check (traveler_id = auth.uid() and status = 'pending' and exists(select 1 from profiles where id = auth.uid() and role = 'traveler'));
create policy "bookings update" on bookings for update to authenticated using (traveler_id = auth.uid() or provider_id = auth.uid());
create policy "messages read" on messages for select to authenticated using (is_party(booking_id));
create policy "messages insert" on messages for insert to authenticated with check (sender_id = auth.uid() and is_party(booking_id));
create policy "itinerary all" on itinerary_items for all to authenticated using (is_party(booking_id)) with check (is_party(booking_id));
create policy "reviews read" on reviews for select to authenticated using (true);
create policy "reviews insert" on reviews for insert to authenticated with check (exists(select 1 from bookings b where b.id = booking_id and b.traveler_id = auth.uid() and b.status = 'completed' and b.provider_id = reviews.provider_id));
create policy "notifications own" on notifications for select to authenticated using (user_id = auth.uid());
create policy "notifications mark read" on notifications for update to authenticated using (user_id = auth.uid());
create policy "audit admin" on audit_log for select to authenticated using (is_admin());
-- column-level limits: users can only change what they should
revoke update on profiles, provider_profiles, bookings, notifications from authenticated, anon;
grant update(full_name) on profiles to authenticated;
grant update(bio, county, languages, rate_usd, vehicle, license_no, services) on provider_profiles to authenticated;
grant update(status) on bookings to authenticated;
grant update(read) on notifications to authenticated;

-- Kenya destinations (images are loaded from each place's Wikipedia article via wiki_title)
insert into destinations(name, county, category, description, activities, wiki_title) values
('Maasai Mara','Narok','Safari','Great Migration and the Big Five.','Game drives, balloon safari, Maasai village visit','Maasai_Mara'),
('Amboseli','Kajiado','Safari','Elephants beneath Mt Kilimanjaro.','Game drives, bird watching','Amboseli_National_Park'),
('Tsavo East & West','Taita Taveta','Safari','Red elephants and Mzima Springs.','Game drives, Mudanda Rock','Tsavo_East_National_Park'),
('Samburu Reserve','Samburu','Safari','Grevy''s zebra and northern species.','Game drives, cultural visits','Samburu_National_Reserve'),
('Ol Pejeta','Laikipia','Safari','Last northern white rhinos.','Rhino tracking, chimp sanctuary','Ol_Pejeta_Conservancy'),
('Nairobi National Park','Nairobi','City','Wildlife beside the skyline.','Game drives, giraffe centre','Nairobi_National_Park'),
('Giraffe Centre','Nairobi','City','Feed giraffes at eye level.','Giraffe feeding, nature trail','Giraffe_Centre'),
('Lake Nakuru','Nakuru','Lake','Rhinos and flamingo shores.','Game drives, Baboon Cliff','Lake_Nakuru_National_Park'),
('Lake Naivasha','Nakuru','Lake','Boat rides, hippos and Hell''s Gate cycling.','Boat rides, cycling','Lake_Naivasha'),
('Lake Bogoria','Baringo','Lake','Geysers, hot springs and flamingos.','Geyser viewing, bird watching','Lake_Bogoria'),
('Lake Turkana','Turkana','Lake','The Jade Sea, a UNESCO site.','Cultural tours, fossil sites','Lake_Turkana'),
('Mount Kenya','Nyeri','Mountain','Africa''s second-highest peak.','Trekking, camping','Mount_Kenya'),
('Aberdare Ranges','Nyandarua','Mountain','Waterfalls and moorland.','Hiking, Karuru Falls','Aberdare_National_Park'),
('Mount Elgon','Trans Nzoia','Mountain','Caves and volcano hikes.','Hiking, Kitum Cave','Mount_Elgon'),
('Kakamega Forest','Kakamega','Forest','Equatorial rainforest and primates.','Guided walks, bird watching','Kakamega_Forest'),
('Kisumu & Lake Victoria','Kisumu','Lake','Sunsets, fishing, Impala Sanctuary.','Boat trips, Dunga beach','Kisumu'),
('Tabaka Soapstone','Kisii','Culture','Home of Kisii soapstone carving.','Craft tours, carving workshops','Tabaka'),
('Diani Beach','Kwale','Beach','White sand, kitesurfing, dhows.','Snorkelling, kitesurfing','Diani_Beach'),
('Watamu & Malindi','Kilifi','Beach','Marine park, reefs and Gedi Ruins.','Snorkelling, Gedi Ruins','Watamu'),
('Lamu Old Town','Lamu','Culture','UNESCO Swahili settlement.','Dhow cruises, donkey tours','Lamu'),
('Fort Jesus','Mombasa','Culture','16th-century fort and spice markets.','Fort tour, old town walk','Fort_Jesus'),
('Shimba Hills','Kwale','Forest','Coastal rainforest, sable antelope.','Walks, Sheldrick Falls','Shimba_Hills_National_Reserve'),
('Chyulu Hills','Makueni','Mountain','Green volcanic hills.','Walking safaris, lava tubes','Chyulu_Hills');
-- After you register your own account, make it admin by running:
--   update profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_EMAIL');
