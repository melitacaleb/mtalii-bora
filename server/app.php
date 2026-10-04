<?php
declare(strict_types=1);
session_start(['cookie_httponly' => true, 'cookie_samesite' => 'Lax']);
header('Content-Type: application/json'); header('X-Content-Type-Options: nosniff');

function db(): PDO {
  static $p; if ($p) return $p;
  $f = __DIR__ . '/../data/mtalii.db'; $new = !file_exists($f);
  $p = new PDO("sqlite:$f", null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
  $p->exec('PRAGMA foreign_keys=ON');
  if ($new) { $p->exec(file_get_contents(__DIR__ . '/schema.sql')); seed($p); }
  return $p;
}
function q(string $sql, array $a = []): PDOStatement { $s = db()->prepare($sql); $s->execute($a); return $s; }
function out($d, int $c = 200): never { http_response_code($c); echo json_encode($d); exit; }
function fail(string $m, int $c = 400): never { out(['error' => $m], $c); }
function body(): array { return json_decode(file_get_contents('php://input') ?: '{}', true) ?: []; }
function me(): ?array { return isset($_SESSION['uid']) ? (q('SELECT id,name,email,role FROM users WHERE id=?', [$_SESSION['uid']])->fetch() ?: null) : null; }
function need(string ...$roles): array { $u = me() or fail('Login required', 401); if ($roles && !in_array($u['role'], $roles)) fail('Forbidden', 403); return $u; }
function audit(string $a, string $d = '', ?int $uid = null): void {
  q('INSERT INTO audit_log(user_id,action,detail,ip) VALUES(?,?,?,?)', [$uid ?? ($_SESSION['uid'] ?? null), $a, $d, $_SERVER['REMOTE_ADDR'] ?? '']);
}
function clean(mixed $v, int $max = 500): string { return mb_substr(trim((string)$v), 0, $max); }

function seed(PDO $p): void {
  $u = $p->prepare('INSERT INTO users(name,email,pass,role) VALUES(?,?,?,?)');
  foreach ([['Admin','admin@mtalii.test','admin'],['Wanjiru Kamau','guide@mtalii.test','guide'],['Otieno Odhiambo','driver@mtalii.test','driver'],['Sarah Miller','traveler@mtalii.test','traveler']] as $r)
    $u->execute([$r[0], $r[1], password_hash($r[2] === 'admin' ? 'Admin123!' : 'Password123!', PASSWORD_DEFAULT), $r[2]]);
  $p->exec("INSERT INTO providers(user_id,type,bio,location,languages,rate,verified) VALUES
   (2,'guide','Cultural and wildlife guide with 8 years in the Mara.','Narok','English, Swahili, French',80,1)");
  $p->exec("INSERT INTO providers(user_id,type,bio,location,languages,rate,vehicle,license_no,verified) VALUES
   (3,'driver','Safari driver, 4x4 pop-up roof Land Cruiser.','Nairobi','English, Swahili',150,'Land Cruiser 4x4 (7 seats)','PSV-0000',0)");
  $d = $p->prepare('INSERT INTO destinations(name,region,description,activities) VALUES(?,?,?,?)');
  foreach ([['Maasai Mara','Narok','Home of the Great Migration.','Game drives, balloon safari, Maasai village visit'],
   ['Amboseli','Kajiado','Elephants with Kilimanjaro views.','Game drives, bird watching'],
   ['Lake Nakuru','Nakuru','Flamingos, rhinos and rift valley scenery.','Game drives, hiking'],
   ['Nairobi National Park','Nairobi','Wildlife against a city skyline.','Game drives, giraffe centre'],
   ['Diani Beach','Kwale','White-sand Indian Ocean coast.','Snorkelling, dhow trips'],
   ['Tabaka Soapstone','Kisii','Home of Kisii soapstone carving.','Craft tours, cultural visits']] as $r) $d->execute($r);
}

$m = $_SERVER['REQUEST_METHOD']; $path = '/' . trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');
$_SESSION['csrf'] ??= bin2hex(random_bytes(16));
if ($m !== 'GET' && !in_array($path, ['/api/login', '/api/register']) && !hash_equals($_SESSION['csrf'], $_SERVER['HTTP_X_CSRF'] ?? '')) fail('Bad CSRF token', 403);

function booking(int $id): array {
  $u = need();
  $b = q('SELECT b.*,p.user_id provider_user FROM bookings b JOIN providers p ON p.id=b.provider_id WHERE b.id=?', [$id])->fetch();
  if (!$b || ($u['id'] !== (int)$b['traveler_id'] && $u['id'] !== (int)$b['provider_user'])) fail('Not found', 404);
  return $b;
}

$routes = [
 ['GET', '#^/api/me$#', fn() => ['user' => me(), 'csrf' => $_SESSION['csrf']]],
 ['POST', '#^/api/register$#', function () {
   $b = body(); $role = $b['role'] ?? 'traveler'; $email = strtolower(clean($b['email'] ?? '', 120));
   if (!in_array($role, ['traveler', 'guide', 'driver'])) fail('Invalid role');
   if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($b['password'] ?? '') < 8 || !clean($b['name'] ?? '', 80)) fail('Name, valid email and 8+ char password required');
   if (q('SELECT 1 FROM users WHERE email=?', [$email])->fetch()) fail('Email already registered', 409);
   q('INSERT INTO users(name,email,pass,role) VALUES(?,?,?,?)', [clean($b['name'], 80), $email, password_hash($b['password'], PASSWORD_DEFAULT), $role]);
   $id = (int)db()->lastInsertId();
   if ($role !== 'traveler') q('INSERT INTO providers(user_id,type) VALUES(?,?)', [$id, $role]);
   session_regenerate_id(true); $_SESSION['uid'] = $id; audit('register', $role, $id);
   return ['user' => me(), 'csrf' => $_SESSION['csrf']];
 }],
 ['POST', '#^/api/login$#', function () {
   $b = body(); $email = strtolower(clean($b['email'] ?? '', 120));
   $fails = q("SELECT COUNT(*) c FROM audit_log WHERE action='login_failed' AND detail=? AND created > datetime('now','-15 minutes')", [$email])->fetch()['c'];
   if ($fails >= 5) fail('Too many attempts. Try again in 15 minutes.', 429);
   $u = q('SELECT * FROM users WHERE email=?', [$email])->fetch();
   if (!$u || !password_verify($b['password'] ?? '', $u['pass'])) { audit('login_failed', $email); fail('Invalid credentials', 401); }
   session_regenerate_id(true); $_SESSION['uid'] = $u['id']; audit('login', '', $u['id']);
   return ['user' => me(), 'csrf' => $_SESSION['csrf']];
 }],
 ['POST', '#^/api/logout$#', function () { audit('logout'); session_destroy(); return ['ok' => true]; }],
 ['GET', '#^/api/destinations$#', fn() => q('SELECT * FROM destinations')->fetchAll()],
 ['GET', '#^/api/providers$#', function () {
   $sql = "SELECT p.*,u.name,(SELECT ROUND(AVG(rating),1) FROM reviews WHERE provider_id=p.id) rating,
     (SELECT COUNT(*) FROM reviews WHERE provider_id=p.id) reviews FROM providers p JOIN users u ON u.id=p.user_id WHERE 1=1";
   $a = [];
   if (in_array($_GET['type'] ?? '', ['guide', 'driver'])) { $sql .= ' AND p.type=?'; $a[] = $_GET['type']; }
   if (($_GET['verified'] ?? '') === '1') $sql .= ' AND p.verified=1';
   if ($s = clean($_GET['q'] ?? '', 50)) { $sql .= ' AND (u.name LIKE ? OR p.location LIKE ? OR p.languages LIKE ?)'; array_push($a, "%$s%", "%$s%", "%$s%"); }
   return q($sql . ' ORDER BY p.verified DESC, rating DESC', $a)->fetchAll();
 }],
 ['GET', '#^/api/providers/(\d+)$#', function ($id) {
   $p = q('SELECT p.*,u.name FROM providers p JOIN users u ON u.id=p.user_id WHERE p.id=?', [$id])->fetch() or fail('Not found', 404);
   $p['reviews'] = q('SELECT r.rating,r.comment,u.name FROM reviews r JOIN bookings b ON b.id=r.booking_id JOIN users u ON u.id=b.traveler_id WHERE r.provider_id=? ORDER BY r.id DESC', [$id])->fetchAll();
   return $p;
 }],
 ['GET', '#^/api/provider/profile$#', fn() => q('SELECT * FROM providers WHERE user_id=?', [need('guide', 'driver')['id']])->fetch()],
 ['POST', '#^/api/provider/profile$#', function () {
   $u = need('guide', 'driver'); $b = body(); $l = clean($b['license_no'] ?? '', 60);
   q('UPDATE providers SET bio=?,location=?,languages=?,rate=?,vehicle=?,verified=CASE WHEN license_no<>? THEN 0 ELSE verified END,license_no=? WHERE user_id=?',
     [clean($b['bio'] ?? ''), clean($b['location'] ?? '', 80), clean($b['languages'] ?? '', 120), max(0, (int)($b['rate'] ?? 0)), clean($b['vehicle'] ?? '', 120), $l, $l, $u['id']]);
   audit('profile_update'); return ['ok' => true];
 }],
 ['POST', '#^/api/bookings$#', function () {
   $u = need('traveler'); $b = body(); $s = $b['start_date'] ?? ''; $e = $b['end_date'] ?? ''; $pid = (int)($b['provider_id'] ?? 0);
   if (!preg_match('/^\d{4}-\d\d-\d\d$/', $s) || !preg_match('/^\d{4}-\d\d-\d\d$/', $e) || $e < $s || $s < date('Y-m-d')) fail('Valid future dates required');
   if (!q('SELECT 1 FROM providers WHERE id=?', [$pid])->fetch()) fail('Unknown provider', 404);
   if (q("SELECT 1 FROM bookings WHERE provider_id=? AND status='accepted' AND start_date<=? AND end_date>=?", [$pid, $e, $s])->fetch()) fail('Provider unavailable on those dates', 409);
   q('INSERT INTO bookings(traveler_id,provider_id,start_date,end_date,note) VALUES(?,?,?,?,?)', [$u['id'], $pid, $s, $e, clean($b['note'] ?? '')]);
   $id = (int)db()->lastInsertId(); audit('booking_create', (string)$id); return ['id' => $id];
 }],
 ['GET', '#^/api/bookings$#', function () {
   $u = need();
   return q("SELECT b.*,tu.name traveler,pu.name provider,p.type FROM bookings b JOIN users tu ON tu.id=b.traveler_id JOIN providers p ON p.id=b.provider_id
     JOIN users pu ON pu.id=p.user_id WHERE b.traveler_id=?1 OR p.user_id=?1 ORDER BY b.id DESC", [$u['id']])->fetchAll();
 }],
 ['GET', '#^/api/bookings/(\d+)$#', function ($id) {
   $b = booking((int)$id);
   $b['messages'] = q('SELECT m.*,u.name FROM messages m JOIN users u ON u.id=m.sender_id WHERE booking_id=? ORDER BY m.id', [$id])->fetchAll();
   $b['items'] = q('SELECT i.*,d.name destination FROM itinerary_items i LEFT JOIN destinations d ON d.id=i.destination_id WHERE booking_id=? ORDER BY day,time', [$id])->fetchAll();
   $b['review'] = q('SELECT rating,comment FROM reviews WHERE booking_id=?', [$id])->fetch() ?: null;
   return $b;
 }],
 ['POST', '#^/api/bookings/(\d+)/status$#', function ($id) {
   $b = booking((int)$id); $u = me(); $to = body()['status'] ?? ''; $mine = $u['id'] === (int)$b['provider_user'];
   $ok = ($mine && $b['status'] === 'pending' && in_array($to, ['accepted', 'rejected']))
      || ($mine && $b['status'] === 'accepted' && $to === 'completed')
      || (!$mine && in_array($b['status'], ['pending', 'accepted']) && $to === 'cancelled');
   if (!$ok) fail('Transition not allowed', 403);
   q('UPDATE bookings SET status=? WHERE id=?', [$to, $id]); audit('booking_' . $to, (string)$id); return ['ok' => true];
 }],
 ['POST', '#^/api/bookings/(\d+)/messages$#', function ($id) {
   booking((int)$id); $t = clean(body()['body'] ?? '', 1000); if (!$t) fail('Empty message');
   q('INSERT INTO messages(booking_id,sender_id,body) VALUES(?,?,?)', [$id, $_SESSION['uid'], $t]); return ['ok' => true];
 }],
 ['POST', '#^/api/bookings/(\d+)/items$#', function ($id) {
   $bk = booking((int)$id); $b = body(); if (in_array($bk['status'], ['rejected', 'cancelled'])) fail('Booking closed');
   if (!clean($b['title'] ?? '')) fail('Title required');
   q('INSERT INTO itinerary_items(booking_id,day,time,title,destination_id,notes) VALUES(?,?,?,?,?,?)',
     [$id, max(1, (int)($b['day'] ?? 1)), clean($b['time'] ?? '', 5), clean($b['title'], 120), ($b['destination_id'] ?? null) ?: null, clean($b['notes'] ?? '')]);
   audit('itinerary_add', (string)$id); return ['ok' => true];
 }],
 ['POST', '#^/api/items/(\d+)/delete$#', function ($id) {
   $i = q('SELECT booking_id FROM itinerary_items WHERE id=?', [$id])->fetch() or fail('Not found', 404);
   booking((int)$i['booking_id']); q('DELETE FROM itinerary_items WHERE id=?', [$id]); return ['ok' => true];
 }],
 ['POST', '#^/api/bookings/(\d+)/review$#', function ($id) {
   $b = booking((int)$id); $x = body(); $r = (int)($x['rating'] ?? 0);
   if ($_SESSION['uid'] !== (int)$b['traveler_id'] || $b['status'] !== 'completed' || $r < 1 || $r > 5) fail('Only travelers of completed bookings may review (1-5)');
   if (q('SELECT 1 FROM reviews WHERE booking_id=?', [$id])->fetch()) fail('Already reviewed', 409);
   q('INSERT INTO reviews(booking_id,provider_id,rating,comment) VALUES(?,?,?,?)', [$id, $b['provider_id'], $r, clean($x['comment'] ?? '')]); return ['ok' => true];
 }],
 ['POST', '#^/api/admin/providers/(\d+)/verify$#', function ($id) {
   need('admin'); $v = body()['verified'] ? 1 : 0;
   q('UPDATE providers SET verified=? WHERE id=?', [$v, $id]); audit('provider_verify', "$id=$v"); return ['ok' => true];
 }],
 ['GET', '#^/api/admin/audit$#', function () { need('admin'); return q('SELECT a.*,u.email FROM audit_log a LEFT JOIN users u ON u.id=a.user_id ORDER BY a.id DESC LIMIT 100')->fetchAll(); }],
];

try {
  foreach ($routes as [$meth, $re, $fn]) if ($m === $meth && preg_match($re, $path, $mt)) { array_shift($mt); out($fn(...$mt)); }
  fail('Not found', 404);
} catch (Throwable $e) { error_log((string)$e); fail('Server error', 500); }
