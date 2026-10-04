# Mtalii Bora — local prototype (PHP + JavaScript)

Traveler ↔ verified guide/driver platform: discovery, booking, messaging, itinerary planning, reviews, admin verification and audit log.

## Run
Requires PHP 8.1+ with `pdo_sqlite` (no Composer/npm).

    cd mtalii-bora
    php -S localhost:8000 -t public public/router.php

Open http://localhost:8000 — the SQLite DB (`data/mtalii.db`) is created and seeded on first request. Delete it to reset.

Demo logins: `traveler@mtalii.test` / `guide@mtalii.test` / `driver@mtalii.test` → `Password123!`; `admin@mtalii.test` → `Admin123!`

## Structure
- `server/app.php`  REST API + routing (one route table), PDO prepared statements
- `server/schema.sql` tables: users, providers, destinations, bookings, messages, itinerary_items, reviews, audit_log
- `public/`  vanilla-JS single-page app (`app.js`), `router.php` dev router

## Security built in (maps to objective 5)
Password hashing (`password_hash`), session ID regeneration, HttpOnly/SameSite cookies, CSRF header on every write,
prepared statements everywhere, output escaping, role + ownership checks (booking participants only),
booking state machine, login throttling (5 failures / 15 min), audit log of sensitive actions, verification reset when licence changes.

## Next steps
Payments (M-Pesa Daraja), email notifications, document upload for verification, image/map support, then port to Next.js + Supabase
(tables map 1:1 to Postgres; Supabase Auth replaces `users.pass`; add Row Level Security mirroring `booking()` checks).
Test with OWASP ZAP / Burp against `localhost:8000`.
