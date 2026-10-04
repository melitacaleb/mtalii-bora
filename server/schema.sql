CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT UNIQUE NOT NULL, pass TEXT NOT NULL,
 role TEXT NOT NULL CHECK(role IN('traveler','guide','driver','admin')), created TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE providers(id INTEGER PRIMARY KEY, user_id INTEGER UNIQUE REFERENCES users(id), type TEXT NOT NULL,
 bio TEXT DEFAULT '', location TEXT DEFAULT '', languages TEXT DEFAULT '', rate INTEGER DEFAULT 0,
 vehicle TEXT DEFAULT '', license_no TEXT DEFAULT '', verified INTEGER DEFAULT 0);
CREATE TABLE destinations(id INTEGER PRIMARY KEY, name TEXT, region TEXT, description TEXT, activities TEXT);
CREATE TABLE bookings(id INTEGER PRIMARY KEY, traveler_id INTEGER REFERENCES users(id), provider_id INTEGER REFERENCES providers(id),
 start_date TEXT, end_date TEXT, note TEXT DEFAULT '',
 status TEXT DEFAULT 'pending' CHECK(status IN('pending','accepted','rejected','completed','cancelled')), created TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE messages(id INTEGER PRIMARY KEY, booking_id INTEGER REFERENCES bookings(id), sender_id INTEGER, body TEXT, created TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE itinerary_items(id INTEGER PRIMARY KEY, booking_id INTEGER REFERENCES bookings(id), day INTEGER, time TEXT,
 title TEXT, destination_id INTEGER, notes TEXT DEFAULT '');
CREATE TABLE reviews(id INTEGER PRIMARY KEY, booking_id INTEGER UNIQUE REFERENCES bookings(id), provider_id INTEGER, rating INTEGER CHECK(rating BETWEEN 1 AND 5), comment TEXT, created TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE audit_log(id INTEGER PRIMARY KEY, user_id INTEGER, action TEXT, detail TEXT, ip TEXT, created TEXT DEFAULT CURRENT_TIMESTAMP);
