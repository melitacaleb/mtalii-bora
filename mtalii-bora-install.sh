#!/usr/bin/env bash
# Mtalii Bora installer — writes the whole PHP + Bootstrap app into the CURRENT folder.
#   bash mtalii-bora-install.sh                  # install only
#   bash mtalii-bora-install.sh --push "msg"     # install, commit and push to GitHub
set -e
REPO="${MB_REPO:-https://github.com/melitacaleb/mtalii-bora.git}"
PUSH=0; MSG="Mtalii Bora: PHP + Bootstrap app with service categories, role dashboards and provider onboarding"
if [ "$1" = "--push" ]; then PUSH=1; [ -n "$2" ] && MSG="$2"; fi
echo "Installing into: $(pwd)"
# remove files from the earlier SQLite/MySQL version and refresh app folders
rm -rf public server data pages includes assets scripts/reset-db.sh scripts/setup-git.sh
cat > "README.md" <<'__MB_EOF__'
# Mtalii Bora — PHP + Bootstrap prototype (no database yet)
Put this folder at C:\xampp\htdocs\mtalii-bora, start Apache, open http://localhost/mtalii-bora/ (or: bash scripts/run.sh -> http://localhost:8000).

## Demo logins (sessions only, no DB)
traveler@mtalii.test / guide@mtalii.test / driver@mtalii.test -> Password123!   |   admin@mtalii.test -> Admin123!
Each role lands on its own page with its own sidebar; protected pages redirect to login.

## Continue with Google (demo button for now)
Real sign-in needs a Google Cloud OAuth client (console.cloud.google.com > APIs & Services > Credentials).
Add redirect URI http://localhost/mtalii-bora/index.php?p=google, then implement the OAuth code flow in the google handler in index.php.
__MB_EOF__
mkdir -p "assets/css"
cat > "assets/css/style.css" <<'__MB_EOF__'
:root{--g:#1f4d3a;--a:#c4623a;--bs-body-font-family:Inter,system-ui,sans-serif;--bs-link-color:#c4623a;--bs-link-hover-color:#a8461f}
[data-bs-theme=light]{--bs-body-bg:#fbf6ee}[data-bs-theme=dark]{--bs-body-bg:#0f1613;--bs-body-color:#eef2ee;--g:#14382a;--bs-link-color:#e07a4f}
h1,h2,h3,h4,.brand{font-family:'Playfair Display',Georgia,serif}
.sidebar{width:250px;flex:none;background:var(--g);color:#fff;display:flex;flex-direction:column;height:100vh;position:sticky;top:0}
@media(max-width:991px){.sidebar{position:fixed;background:var(--g)!important}}
.brand{color:#fff;text-decoration:none;font-size:24px;font-weight:700;padding:20px 22px 10px}.brand b{color:#f4b183}
.nav-h{font-size:11px;letter-spacing:.12em;text-transform:uppercase;opacity:.55;margin:16px 12px 6px}
.nav-i{display:block;color:#fff;text-decoration:none;padding:8px 12px;border-radius:10px;opacity:.88;font-size:14.5px}.nav-i:hover{background:#ffffff22;color:#fff}.nav-i.on{background:var(--a);opacity:1}.nav-i i{margin-right:6px}
.topbar{padding:10px 14px;background:var(--g);color:#fff;display:flex;align-items:center}.min-w-0{min-width:0}
.btn-accent{background:var(--a);color:#fff;border:0;border-radius:99px;padding:.55rem 1.4rem}.btn-accent:hover{background:#a8461f;color:#fff}
.card{border-radius:16px;box-shadow:0 6px 22px #14263a14}
.hero{border-radius:26px;padding:clamp(28px,6vw,72px);min-height:380px;color:#fff;display:flex;flex-direction:column;justify-content:center;box-shadow:0 10px 30px #0003;
 background:radial-gradient(circle at 78% 30%,#ffd27a 0 7%,#f59e4a 7.5% 16%,transparent 16.5%),linear-gradient(180deg,#f6b26b 0%,#c4623a 48%,#3b2a24 49%,#1f4d3a 100%)}
.hero h1{font-size:clamp(34px,6vw,60px);line-height:1.05;max-width:640px;text-shadow:0 2px 12px #0005}
.search-pill{background:var(--bs-body-bg);border-radius:99px;padding:6px;max-width:640px;box-shadow:0 8px 24px #0004}.search-pill input{border:0;background:none;box-shadow:none;color:var(--bs-body-color)}
.dcard{overflow:hidden}.dcard .pic{height:120px;position:relative;display:flex;align-items:flex-end;padding:10px}.dcard .emoji{font-size:38px}.dcard .badge{position:absolute;top:10px;right:10px}
.feat i{font-size:1.9rem;color:var(--a)}.stat b{font:700 2.2rem 'Playfair Display',serif;color:var(--a);display:block}
.cta{border-radius:24px;padding:36px;color:#fff;background:linear-gradient(120deg,#1f4d3a,#14263a)}
.avatar{width:48px;height:48px;border-radius:50%;background:var(--g);color:#fff;display:grid;place-items:center;font-weight:600;flex:none}
.cal{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;text-align:center}.cal div{padding:8px 0;border-radius:8px;font-size:14px;background:#2e9e6a22}.cal .h{background:none;font-weight:600}.cal .x{background:#d6454533;text-decoration:line-through}.cal .e{background:none}
.bubble{padding:8px 14px;border-radius:16px;max-width:75%;margin-bottom:8px;background:var(--bs-secondary-bg)}.bubble.me{background:var(--a);color:#fff;margin-left:auto}
.timeline{border-left:3px solid var(--a);padding-left:18px}.timeline .item{position:relative;margin-bottom:14px}.timeline .item:before{content:'';position:absolute;left:-26px;top:6px;width:12px;height:12px;border-radius:50%;background:var(--a)}
.wiz .pill{background:var(--bs-secondary-bg);color:var(--bs-body-color);padding:.5rem 1rem;font-weight:500}.wiz .pill.active{background:var(--a);color:#fff}
.svc{text-decoration:none;color:inherit;display:block}.svc i{font-size:1.8rem;color:var(--a)}.svc:hover{transform:translateY(-3px)}.svc{transition:.15s}
__MB_EOF__
mkdir -p "assets/js"
cat > "assets/js/app.js" <<'__MB_EOF__'
const root = document.documentElement, btn = document.getElementById('themeBtn');
const paint = () => btn.innerHTML = root.dataset.bsTheme === 'dark' ? '<i class="bi bi-sun"></i> Light mode' : '<i class="bi bi-moon-stars"></i> Dark mode';
btn.onclick = () => { root.dataset.bsTheme = root.dataset.bsTheme === 'dark' ? 'light' : 'dark'; localStorage.setItem('theme', root.dataset.bsTheme); paint(); };
paint();
document.querySelectorAll('form[data-demo]').forEach(f => f.addEventListener('submit', e => { e.preventDefault(); bootstrap.Toast.getOrCreateInstance(document.getElementById('demoToast')).show(); }));
document.querySelectorAll('.wiz').forEach(w => {
  const s = [...w.querySelectorAll('.step')], p = [...w.querySelectorAll('.pill')], q = c => w.querySelector(c); let i = 0;
  const show = n => { i = n; s.forEach((e, k) => e.classList.toggle('d-none', k != i)); p.forEach((e, k) => e.classList.toggle('active', k <= i)); q('.prev').disabled = i == 0; q('.next').classList.toggle('d-none', i == s.length - 1); q('.done').classList.toggle('d-none', i != s.length - 1); };
  q('.next').onclick = () => { const bad = [...s[i].querySelectorAll('input,select,textarea')].find(x => !x.checkValidity()); if (bad) return bad.reportValidity(); show(i + 1); };
  q('.prev').onclick = () => show(i - 1); show(0);
});
__MB_EOF__
mkdir -p "includes"
cat > "includes/data.php" <<'__MB_EOF__'
<?php
function e($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
$CAT = ['Safari'=>['#e9a23b','#a8461f','🦁'],'Beach'=>['#2bb3b1','#0b4f6c','🏖️'],'Mountain'=>['#7a9cc0','#1b3a4b','⛰️'],'Lake'=>['#3aa6c9','#14506b','🦩'],'Culture'=>['#c0782f','#4a2511','🏛️'],'City'=>['#8a96a3','#243b53','🌆'],'Forest'=>['#4f9d69','#17402b','🌳']];
$D = [['Maasai Mara','Narok','Safari','Great Migration and the Big Five.'],['Amboseli','Kajiado','Safari','Elephants beneath Mt Kilimanjaro.'],['Tsavo East & West','Taita Taveta','Safari','Red elephants and Mzima Springs.'],
['Samburu Reserve','Samburu','Safari',"Grevy's zebra and northern species."],['Ol Pejeta','Laikipia','Safari','Last northern white rhinos.'],['Nairobi National Park','Nairobi','City','Wildlife beside the skyline.'],
['Giraffe Centre & Karen Blixen','Nairobi','City','Giraffe feeding and colonial heritage.'],['Lake Nakuru','Nakuru','Lake','Rhinos and flamingo shores.'],["Naivasha & Hell's Gate",'Nakuru','Lake','Boat rides, cycling and gorges.'],
['Lake Bogoria & Baringo','Baringo','Lake','Geysers, hot springs and birdlife.'],['Lake Turkana','Turkana','Lake','The Jade Sea, a UNESCO site.'],['Mount Kenya','Nyeri','Mountain',"Africa's second-highest peak."],
['Aberdare Ranges','Nyandarua','Mountain','Waterfalls and moorland.'],['Mount Elgon','Trans Nzoia','Mountain','Caves and volcano hikes.'],['Kakamega Forest','Kakamega','Forest','Equatorial rainforest and primates.'],
['Kisumu & Lake Victoria','Kisumu','Lake','Sunsets, fishing, Impala Sanctuary.'],['Tabaka Soapstone','Kisii','Culture','Home of Kisii soapstone carving.'],['Diani Beach','Kwale','Beach','White sand, kitesurfing, dhows.'],
['Watamu & Malindi','Kilifi','Beach','Marine park, reefs and Gedi Ruins.'],['Lamu Old Town','Lamu','Culture','UNESCO Swahili settlement.'],['Fort Jesus & Old Town','Mombasa','Culture','16th-century fort and spice markets.'],
['Shimba Hills','Kwale','Forest','Coastal rainforest, sable antelope.'],['Chyulu Hills','Makueni','Mountain','Green volcanic hills.']];
// id, name, type, county, languages, rate USD/day, verified, rating, reviews, bio, vehicle, busy [[from+days, to+days]]
$P = [[1,'Wanjiru Kamau','guide','Narok','English, Swahili, French',80,true,4.9,32,'Cultural and wildlife guide with 8 years in the Mara.','',[[5,8]]],
[2,'Otieno Odhiambo','driver','Nairobi','English, Swahili',150,true,4.8,21,'Safari driver with a pop-up roof 4x4 Land Cruiser.','Land Cruiser 4x4 (7 seats)',[[2,4],[12,15]]],
[3,'Kiprono Rotich','guide','Nakuru','English, Swahili, Kalenjin',70,true,4.7,14,'Birding and Rift Valley lakes specialist.','',[]],
[4,'Amina Hassan','guide','Lamu','English, Swahili, Arabic',65,true,4.9,18,'Swahili heritage and dhow tours on the coast.','',[[9,11]]],
[5,'Brian Mwangi','driver','Mombasa','English, Swahili',130,false,0,0,'Coast and Tsavo transfers in a Toyota Hiace.','Toyota Hiace (9 seats)',[]],
[6,'Nyaboke Ongeri','guide','Kisii','English, Swahili, Ekegusii',55,false,0,0,'Tabaka soapstone and Kisii culture tours.','',[]]];
$B = [[101,1,'Oct 21 – Oct 25, 2026','Pending',400],[102,2,'Nov 02 – Nov 04, 2026','Accepted',450],[103,3,'Aug 10 – Aug 12, 2026','Completed',210],[104,4,'Jul 01 – Jul 03, 2026','Completed',195],[105,5,'Jun 14 – Jun 15, 2026','Cancelled',130]];
function prov($id) { global $P; foreach ($P as $p) if ($p[0] == $id) return $p; return $P[0]; }
function dcard($d) { global $CAT; $g = $CAT[$d[2]]; ob_start(); ?>
<div class="col"><div class="card dcard h-100"><div class="pic" style="background:linear-gradient(160deg,<?= $g[0] ?>,<?= $g[1] ?>)"><span class="emoji"><?= $g[2] ?></span><span class="badge text-bg-dark"><?= e($d[2]) ?></span></div>
<div class="card-body"><h6 class="mb-0"><?= e($d[0]) ?></h6><small class="text-body-secondary"><i class="bi bi-geo-alt"></i> <?= e($d[1]) ?></small><p class="small mt-2 mb-2"><?= e($d[3]) ?></p>
<a href="?p=search&q=<?= urlencode($d[1]) ?>" class="small">Find a guide →</a></div></div></div>
<?php return ob_get_clean(); }
function status_badge($s) { $c = ['Pending'=>'warning','Accepted'=>'success','Completed'=>'primary','Cancelled'=>'secondary','Rejected'=>'danger'][$s] ?? 'secondary'; return "<span class='badge text-bg-$c'>" . e($s) . '</span>'; }
function vbadge($v) { return $v ? '<span class="badge text-bg-success"><i class="bi bi-patch-check-fill"></i> Verified</span>' : '<span class="badge text-bg-secondary">Pending verification</span>'; }
function stars($r) { return $r ? '<i class="bi bi-star-fill text-warning"></i> ' . number_format($r, 1) : '<span class="text-body-secondary">New</span>'; }
// ---- Service categories, demo users (no DB yet), form helper
$SVC = ['safari'=>['Wildlife safaris','binoculars','Game drives and Big Five tracking'],'culture'=>['Cultural & heritage','bank','Villages, museums and Swahili heritage'],'coast'=>['Coast & beach','umbrella','Dhow trips, snorkelling and beaches'],
'hiking'=>['Mountain & hiking','signpost-split','Mt Kenya, Hell\'s Gate and forest walks'],'transfer'=>['Airport & transfers','airplane','Pickups, road transfers and safari vehicles'],'birding'=>['Birding & photography','camera','Lakes, hides and photo safaris']];
$SVCMAP = [1=>['safari','culture'],2=>['safari','transfer'],3=>['birding','hiking'],4=>['culture','coast'],5=>['transfer','coast'],6=>['culture']];
// Demo accounts only. The real app will use password_hash() and a database.
$USERS = ['traveler@mtalii.test'=>['Sarah Miller','traveler','Password123!'],'guide@mtalii.test'=>['Wanjiru Kamau','guide','Password123!'],'driver@mtalii.test'=>['Otieno Odhiambo','driver','Password123!'],'admin@mtalii.test'=>['Admin','admin','Admin123!']];
function field($l, $n, $t = 'text', $x = '', $w = 'col-md-6') { return "<div class='$w'><label class='form-label'>$l</label><input type='$t' name='$n' class='form-control' $x></div>"; }
function google_btn($label = 'Continue with Google') { return '<a href="?p=google" class="btn btn-outline-secondary w-100 d-flex align-items-center justify-content-center gap-2"><svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.6 5.9c4.4-4.1 7-10.1 7-17.6z"/><path fill="#FBBC05" d="M10.5 28.7c-.5-1.4-.8-3-.8-4.7s.3-3.2.8-4.7l-7.9-6.1C.9 16.4 0 20.1 0 24s.9 7.6 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.6-5.9c-2.1 1.4-4.9 2.3-8.3 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>' . e($label) . '</a>'; }
function wizard($title, $steps) { ?>
<form data-demo class="wiz card p-4"><h3><?= e($title) ?></h3><div class="d-flex gap-2 flex-wrap my-3"><?php foreach ($steps as $i => $s): ?><span class="pill badge rounded-pill"><?= $i + 1 ?>. <?= e($s[0]) ?></span><?php endforeach; ?></div>
<?php foreach ($steps as $i => $s): ?><div class="step row g-3"><?= $s[1] ?></div><?php endforeach; ?>
<div class="d-flex justify-content-between mt-4"><button type="button" class="btn btn-outline-secondary prev">Back</button><button type="button" class="btn btn-accent next">Next</button><button class="btn btn-accent done d-none">Submit application</button></div></form>
<?php }
__MB_EOF__
mkdir -p "includes"
cat > "includes/footer.php" <<'__MB_EOF__'
</main><footer class="container-xl px-4 py-4 small text-body-secondary border-top">© <?= date('Y') ?> Mtalii Bora · Verified local guides &amp; safari drivers across Kenya · Prototype with sample data</footer></div></div>
<div class="toast-container position-fixed bottom-0 end-0 p-3"><div id="demoToast" class="toast text-bg-success"><div class="toast-body">Demo only — this will be saved once the database is connected.</div></div></div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script><script src="assets/js/app.js"></script></body></html>
__MB_EOF__
mkdir -p "includes"
cat > "includes/header.php" <<'__MB_EOF__'
<?php
$role = $u['role'] ?? 'guest';
$explore = [['destinations','map','Destinations'],['services','grid','Service categories'],['search','search','Search & filter'],['search&type=guide','people','Tour guides'],['search&type=driver','car-front','Safari drivers']];
$trips = [['bookings','calendar-check','Bookings'],['bookings&tab=history','clock-history','Booking history'],['itinerary','list-check','Itinerary planner'],['messages','chat-dots','Messages'],['reviews','star','Reviews & ratings'],['notifications','bell','Notifications']];
if ($role == 'traveler') $nav = ['Explore'=>array_merge([['dashboard','compass','Explore home']], $explore), 'My trips'=>$trips];
elseif ($role == 'guide' || $role == 'driver') $nav = ['Provider'=>[['pro','speedometer2','Dashboard'],['verification','patch-check','Verification'],['provider&id=' . ($role == 'guide' ? 1 : 2),'calendar3','My profile & availability'],['bookings','calendar-check','Booking requests'],['messages','chat-dots','Messages'],['reviews','star','Reviews'],['notifications','bell','Notifications']]];
elseif ($role == 'admin') $nav = ['Admin'=>[['admin','shield-lock','Administration'],['security','activity','Security & audit']], 'Browse'=>$explore];
else $nav = ['Explore'=>array_merge([['home','house','Home']], $explore), 'Traveler'=>[['signup','person-plus','Create account'],['login','box-arrow-in-right','Login']],
  'Provider onboarding'=>[['join','briefcase','Overview'],['guide_signup','compass','Tour guide sign-up'],['driver_signup','truck-front','Driver sign-up']]];
$cur = $p . (isset($_GET['tab']) ? '&tab=' . $_GET['tab'] : '') . (isset($_GET['type']) && $p == 'search' ? '&type=' . $_GET['type'] : '') . (isset($_GET['id']) && $p == 'provider' ? '&id=' . (int)$_GET['id'] : '');
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mtalii Bora — Discover Kenya with verified local experts</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Playfair+Display:wght@600;700&display=swap" rel="stylesheet">
<link href="assets/css/style.css" rel="stylesheet">
<script>document.documentElement.dataset.bsTheme=localStorage.getItem('theme')||(matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light')</script></head>
<body><div class="d-flex">
<aside class="offcanvas-lg offcanvas-start sidebar" tabindex="-1" id="side"><div class="offcanvas-header d-lg-none"><button class="btn-close btn-close-white" data-bs-dismiss="offcanvas"></button></div>
<a class="brand" href="?p=<?= $u ? $landing[$u['role']] : 'home' ?>">🦒 Mtalii <b>Bora</b></a>
<nav class="px-2 flex-grow-1 overflow-auto"><?php foreach ($nav as $group => $items): ?><div class="nav-h"><?= e($group) ?></div>
<?php foreach ($items as $i): $key = explode('#', $i[0])[0]; ?><a class="nav-i <?= $key === $cur ? 'on' : '' ?>" href="?p=<?= $i[0] ?>"><i class="bi bi-<?= $i[1] ?>"></i> <?= e($i[2]) ?></a><?php endforeach; endforeach; ?></nav>
<div class="p-3"><?php if ($u): ?><div class="small mb-2"><i class="bi bi-person-circle"></i> <?= e($u['name']) ?> <span class="badge text-bg-light"><?= e($u['role']) ?></span></div><a href="?p=logout" class="btn btn-sm btn-light w-100 mb-2">Logout</a><?php endif; ?><button id="themeBtn" class="btn btn-sm btn-outline-light w-100"></button></div></aside>
<div class="flex-grow-1 min-w-0"><div class="topbar d-lg-none"><button class="btn btn-light btn-sm" data-bs-toggle="offcanvas" data-bs-target="#side"><i class="bi bi-list"></i> Menu</button><b class="ms-2">Mtalii Bora</b></div>
<main class="container-xl py-4 px-3 px-lg-4">
__MB_EOF__
cat > "index.php" <<'__MB_EOF__'
<?php
// Front controller: index.php?p=<page>. Demo sessions only — no database yet.
session_start(['cookie_httponly' => true, 'cookie_samesite' => 'Lax']);
require __DIR__ . '/includes/data.php';
function go($p) { header('Location: ?p=' . $p); exit; }
$landing = ['traveler' => 'dashboard', 'guide' => 'pro', 'driver' => 'pro', 'admin' => 'admin'];
$pages = ['home','login','signup','join','guide_signup','driver_signup','dashboard','pro','services','destinations','search','provider','verification','bookings','messages','itinerary','reviews','notifications','admin','security','google','logout'];
$p = $_GET['p'] ?? 'home';
if (!in_array($p, $pages, true)) { http_response_code(404); $p = '404'; }
$u = $_SESSION['user'] ?? null;
$_SESSION['csrf'] ??= bin2hex(random_bytes(16));
$all = ['traveler', 'guide', 'driver', 'admin'];
$need = ['dashboard'=>['traveler'],'pro'=>['guide','driver'],'admin'=>['admin'],'security'=>['admin'],'verification'=>['guide','driver'],'bookings'=>$all,'messages'=>$all,'itinerary'=>$all,'reviews'=>$all,'notifications'=>$all];
if (isset($need[$p]) && (!$u || !in_array($u['role'], $need[$p]))) go('login');
if ($p === 'home' && $u) go($landing[$u['role']]);
$err = '';
if ($p === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
  $em = strtolower(trim($_POST['email'] ?? '')); $acc = $USERS[$em] ?? null;
  if (!hash_equals($_SESSION['csrf'], $_POST['csrf'] ?? '')) $err = 'Session expired. Please try again.';
  elseif (!$acc || !hash_equals($acc[2], $_POST['password'] ?? '')) $err = 'Invalid email or password.';
  else { session_regenerate_id(true); $_SESSION['user'] = ['name' => $acc[0], 'email' => $em, 'role' => $acc[1]]; go($landing[$acc[1]]); }
}
if ($p === 'google') { // DEMO: real Google OAuth needs a Google Cloud client ID/secret (see README)
  session_regenerate_id(true); $_SESSION['user'] = ['name' => 'Google Traveler', 'email' => 'demo.google@gmail.com', 'role' => 'traveler']; go('dashboard');
}
if ($p === 'logout') { $_SESSION = []; session_destroy(); go('login'); }
require __DIR__ . '/includes/header.php';
require __DIR__ . "/pages/$p.php";
require __DIR__ . '/includes/footer.php';
__MB_EOF__
mkdir -p "pages"
cat > "pages/404.php" <<'__MB_EOF__'
<div class="text-center py-5"><h1>404</h1><p>That page doesn't exist.</p><a class="btn btn-accent" href="?p=home">Back to home</a></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/admin.php" <<'__MB_EOF__'
<h2>Administration</h2><div class="row row-cols-2 row-cols-lg-4 g-3 text-center mb-3 stat">
<?php foreach ([['128','Users'],['24','Providers'],['3','Awaiting verification'],['57','Bookings this month']] as $s): ?><div class="col"><div class="card p-3"><b><?= $s[0] ?></b><?= $s[1] ?></div></div><?php endforeach; ?></div>
<div class="card p-3 mb-3"><h5>Verification queue</h5><table class="table align-middle mb-0"><tbody>
<?php foreach ($P as $x) if (!$x[6]): ?><tr><td><b><?= e($x[1]) ?></b><br><small class="text-body-secondary"><?= ucfirst($x[2]) ?> · <?= e($x[3]) ?></small></td><td>Licence no. LIC-<?= 1000 + $x[0] ?></td><td class="text-end"><form data-demo><button class="btn btn-sm btn-success">Verify</button> <button class="btn btn-sm btn-outline-danger">Reject</button></form></td></tr><?php endif; ?></tbody></table></div>
<div class="card p-3"><h5>Users & providers</h5><div class="table-responsive"><table class="table mb-0"><thead><tr><th>Name</th><th>Role</th><th>County</th><th>Status</th></tr></thead><tbody>
<?php foreach ($P as $x): ?><tr><td><?= e($x[1]) ?></td><td><?= ucfirst($x[2]) ?></td><td><?= e($x[3]) ?></td><td><?= vbadge($x[6]) ?></td></tr><?php endforeach; ?></tbody></table></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/bookings.php" <<'__MB_EOF__'
<?php $tab = $_GET['tab'] ?? 'active'; $rows = array_filter($B, fn($b) => $tab == 'history' ? in_array($b[3], ['Completed', 'Cancelled']) : in_array($b[3], ['Pending', 'Accepted'])); ?>
<h2><?= $tab == 'history' ? 'Booking history' : 'Booking management' ?></h2>
<ul class="nav nav-tabs mb-3"><li class="nav-item"><a class="nav-link <?= $tab != 'history' ? 'active' : '' ?>" href="?p=bookings">Active</a></li><li class="nav-item"><a class="nav-link <?= $tab == 'history' ? 'active' : '' ?>" href="?p=bookings&tab=history">History</a></li></ul>
<div class="card"><div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th>#</th><th>Provider</th><th>Dates</th><th>Total</th><th>Status</th><th></th></tr></thead><tbody>
<?php foreach ($rows as $b): $pv = prov($b[1]); ?><tr><td><?= $b[0] ?></td><td><a href="?p=provider&id=<?= $pv[0] ?>"><?= e($pv[1]) ?></a></td><td><?= $b[2] ?></td><td>$<?= $b[4] ?></td><td><?= status_badge($b[3]) ?></td>
<td class="text-end"><form data-demo class="d-inline"><?php if ($b[3] == 'Pending'): ?><button class="btn btn-sm btn-success">Accept</button> <button class="btn btn-sm btn-outline-danger">Reject</button>
<?php elseif ($b[3] == 'Accepted'): ?><a href="?p=itinerary" class="btn btn-sm btn-outline-secondary">Itinerary</a> <button class="btn btn-sm btn-outline-danger">Cancel</button>
<?php elseif ($b[3] == 'Completed'): ?><a href="?p=reviews" class="btn btn-sm btn-outline-secondary">Review</a><?php endif; ?></form></td></tr><?php endforeach; ?></tbody></table></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/dashboard.php" <<'__MB_EOF__'
<div class="d-flex justify-content-between flex-wrap gap-2 align-items-end mb-3"><div><small class="text-body-secondary">Karibu,</small><h2 class="mb-0"><?= e(explode(' ', $u['name'])[0]) ?> 👋</h2></div>
<div class="card p-3"><small class="text-body-secondary">Next trip</small><b>Maasai Mara · 21–25 Oct</b><small><?= status_badge('Pending') ?> with Wanjiru Kamau</small></div></div>
<section class="mb-4"><div class="d-flex justify-content-between align-items-baseline"><h3>Explore by service</h3><a href="?p=services">All categories →</a></div>
<div class="row row-cols-2 row-cols-lg-3 g-3"><?php foreach ($SVC as $k => $v): ?><div class="col"><a class="card p-3 h-100 svc" href="?p=search&svc=<?= $k ?>"><i class="bi bi-<?= $v[1] ?>"></i><b><?= e($v[0]) ?></b><small class="text-body-secondary"><?= e($v[2]) ?></small></a></div><?php endforeach; ?></div></section>
<section class="mb-4"><div class="d-flex justify-content-between align-items-baseline"><h3>Explore destinations</h3><a href="?p=destinations">View all →</a></div>
<div class="row row-cols-1 row-cols-sm-2 row-cols-xl-3 g-3"><?php foreach ([0, 17, 19, 11, 7, 16] as $i) echo dcard($D[$i]); ?></div></section>
<section class="mb-4"><div class="d-flex justify-content-between align-items-baseline"><h3>Top-rated guides &amp; drivers</h3><a href="?p=search">Browse all →</a></div>
<div class="row row-cols-1 row-cols-md-3 g-3"><?php foreach (array_slice($P, 0, 3) as $x): ?><div class="col"><a class="card p-3 h-100 text-decoration-none" href="?p=provider&id=<?= $x[0] ?>"><div class="d-flex gap-3 align-items-center"><div class="avatar"><?= e($x[1][0]) ?></div><div><b><?= e($x[1]) ?></b><br><?= vbadge($x[6]) ?></div></div>
<small class="text-body-secondary mt-2"><?= ucfirst($x[2]) ?> · <?= e($x[3]) ?> · $<?= $x[5] ?>/day · <?= stars($x[7]) ?></small></a></div><?php endforeach; ?></div></section>
__MB_EOF__
mkdir -p "pages"
cat > "pages/destinations.php" <<'__MB_EOF__'
<?php $cat = $_GET['cat'] ?? ''; $list = array_filter($D, fn($d) => !$cat || $d[2] == $cat); ?>
<h2>Destinations across Kenya</h2><p class="text-body-secondary"><?= count($D) ?> places in <?= count(array_unique(array_column($D, 1))) ?> counties.</p>
<div class="mb-3 d-flex gap-2 flex-wrap"><a class="btn btn-sm <?= $cat ? 'btn-outline-secondary' : 'btn-success' ?>" href="?p=destinations">All</a>
<?php foreach (array_keys($CAT) as $c): ?><a class="btn btn-sm <?= $cat == $c ? 'btn-success' : 'btn-outline-secondary' ?>" href="?p=destinations&cat=<?= $c ?>"><?= $CAT[$c][2] . ' ' . $c ?></a><?php endforeach; ?></div>
<div class="row row-cols-1 row-cols-sm-2 row-cols-xl-4 g-3"><?php foreach ($list as $d) echo dcard($d); ?></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/driver_signup.php" <<'__MB_EOF__'
<div class="mb-2"><a href="?p=join" class="small">← Provider onboarding</a></div>
<?php wizard('Safari driver application', [
 ['Account', field('Full name', 'name', 'text', 'required') . field('Email', 'email', 'email', 'required') . field('Password (8+ characters)', 'password', 'password', 'minlength=8 required') . field('Phone', 'phone', 'tel', 'required') . '<div class="col-12">' . google_btn('Prefill with Google') . '</div>'],
 ['Vehicle & driving', field('County / base', 'county', 'text', 'required') . field('Languages spoken', 'langs', 'text', 'required') . field('Years driving safaris', 'exp', 'number', 'min=0 required') . field('Daily rate (USD)', 'rate', 'number', 'min=0 required') . field('Vehicle make & model', 'veh', 'text', 'required') . field('Passenger seats', 'seats', 'number', 'min=1 required') . field('Number plate', 'plate', 'text', 'required') . field('PSV / driving licence no.', 'lic', 'text', 'required') . field('Service areas (e.g. Nairobi, Mara, Coast)', 'areas', 'text', '', 'col-12')],
 ['Documents', "<div class='col-md-6'><label class='form-label'>National ID</label><input type='file' class='form-control' required></div><div class='col-md-6'><label class='form-label'>Driving licence / PSV badge</label><input type='file' class='form-control' required></div><div class='col-md-6'><label class='form-label'>Insurance certificate</label><input type='file' class='form-control' required></div><div class='col-md-6'><label class='form-label'>Vehicle inspection sticker</label><input type='file' class='form-control'></div><div class='col-12'><label><input type='checkbox' class='form-check-input' required> I confirm the details are true and accept the terms.</label></div>"]]); ?>
__MB_EOF__
mkdir -p "pages"
cat > "pages/guide_signup.php" <<'__MB_EOF__'
<div class="mb-2"><a href="?p=join" class="small">← Provider onboarding</a></div>
<?php $chk = ''; foreach ($SVC as $v) $chk .= '<label class="me-3"><input type="checkbox" class="form-check-input"> ' . e($v[0]) . '</label>';
wizard('Tour guide application', [
 ['Account', field('Full name', 'name', 'text', 'required') . field('Email', 'email', 'email', 'required') . field('Password (8+ characters)', 'password', 'password', 'minlength=8 required') . field('Phone', 'phone', 'tel', 'required') . '<div class="col-12">' . google_btn('Prefill with Google') . '</div>'],
 ['Professional details', field('County / base', 'county', 'text', 'required') . field('Languages spoken', 'langs', 'text', 'required') . field('Years of experience', 'exp', 'number', 'min=0 required') . field('Daily rate (USD)', 'rate', 'number', 'min=0 required') . field('Tourism guide licence no.', 'lic', 'text', 'required') . "<div class='col-12'><label class='form-label'>Specialisations</label><div>$chk</div></div><div class='col-12'><label class='form-label'>Short bio</label><textarea class='form-control' rows='3'></textarea></div>"],
 ['Documents', "<div class='col-md-6'><label class='form-label'>National ID</label><input type='file' class='form-control' required></div><div class='col-md-6'><label class='form-label'>Guide licence</label><input type='file' class='form-control' required></div><div class='col-md-6'><label class='form-label'>Certificate of good conduct</label><input type='file' class='form-control'></div><div class='col-md-6'><label class='form-label'>First-aid certificate</label><input type='file' class='form-control'></div><div class='col-12'><label><input type='checkbox' class='form-check-input' required> I confirm the details are true and accept the terms.</label></div>"]]); ?>
__MB_EOF__
mkdir -p "pages"
cat > "pages/home.php" <<'__MB_EOF__'
<section class="hero"><small class="text-uppercase">Explore Kenya</small><h1>Discover Kenya with trusted local experts</h1>
<p class="lead" style="max-width:520px">Verified guides and safari drivers, one booking, one itinerary — from the Mara to the coast.</p>
<form action="" method="get" class="search-pill d-flex mt-3"><input type="hidden" name="p" value="search"><input name="q" class="form-control" placeholder="Search by name, county or language"><button class="btn btn-accent">Search</button></form><div class="mt-3 d-flex gap-2 flex-wrap"><a class="btn btn-light rounded-pill" href="?p=signup">Create traveler account</a><a class="btn btn-outline-light rounded-pill" href="?p=join">Become a provider</a><a class="btn btn-outline-light rounded-pill" href="?p=login">Login</a></div></section>
<div class="row row-cols-2 row-cols-lg-4 g-3 text-center my-4 feat">
<?php foreach ([['patch-check','Verified providers','Licence checks by admins'],['calendar-check','Quick booking','Request in minutes'],['compass','Local experts','Guides who know every corner'],['list-check','Shared itineraries','Plan day by day together']] as $f): ?>
<div class="col"><i class="bi bi-<?= $f[0] ?>"></i><div class="fw-semibold"><?= $f[1] ?></div><small class="text-body-secondary"><?= $f[2] ?></small></div><?php endforeach; ?></div>
<div class="d-flex justify-content-between align-items-baseline mt-4"><h2>Popular destinations</h2><a href="?p=destinations">View all →</a></div>
<div class="row row-cols-1 row-cols-sm-2 row-cols-xl-4 g-3"><?php foreach (array_slice($D, 0, 4) as $d) echo dcard($d); ?></div>
<div class="row row-cols-2 row-cols-md-4 g-3 text-center my-4">
<?php foreach ([[count($D),'Destinations'],[count(array_unique(array_column($D, 1))),'Counties'],[count($P),'Providers'],[count(array_filter($P, fn($x) => $x[6])),'Verified']] as $s): ?>
<div class="col"><div class="card stat p-3"><b><?= $s[0] ?></b><?= $s[1] ?></div></div><?php endforeach; ?></div>
<div class="cta"><h2>Your next Kenyan adventure starts here</h2><p>Browse verified guides and drivers, agree an itinerary, and travel with confidence.</p><a class="btn btn-accent" href="?p=search&type=guide">Meet our guides</a></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/itinerary.php" <<'__MB_EOF__'
<?php $days = [['Day 1 · Nairobi → Maasai Mara',[['07:00','Pickup in Nairobi','Otieno Odhiambo'],['13:00','Lunch at Narok','Local restaurant'],['16:00','Evening game drive','Maasai Mara']]],
['Day 2 · Maasai Mara',[['06:30','Sunrise game drive','Look for the Big Five'],['11:00','Maasai village visit','Cultural experience'],['15:30','Mara River viewpoint','Migration season']]],['Day 3 · Return',[['08:00','Breakfast and checkout',''],['09:30','Drive to Nairobi','']]]]; ?>
<div class="d-flex justify-content-between"><h2>Itinerary planner</h2><span class="badge text-bg-success align-self-center">Booking #102 · Mara 3-day safari</span></div>
<div class="row g-3"><div class="col-lg-8"><?php foreach ($days as $d): ?><div class="card p-3 mb-3"><h5><?= $d[0] ?></h5><div class="timeline"><?php foreach ($d[1] as $i): ?><div class="item"><b><?= $i[0] ?></b> · <?= $i[1] ?> <small class="text-body-secondary d-block"><?= $i[2] ?></small></div><?php endforeach; ?></div></div><?php endforeach; ?></div>
<div class="col-lg-4"><form data-demo class="card p-3"><h5>Add activity</h5><label class="form-label small">Day</label><input type="number" min="1" value="1" class="form-control mb-2"><label class="form-label small">Time</label><input type="time" class="form-control mb-2">
<label class="form-label small">Activity</label><input class="form-control mb-2" required><label class="form-label small">Destination</label><select class="form-select mb-3"><?php foreach ($D as $d) echo '<option>' . e($d[0]) . '</option>'; ?></select><button class="btn btn-accent w-100">Add to itinerary</button></form></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/join.php" <<'__MB_EOF__'
<h2>Provider onboarding</h2><p class="text-body-secondary">Join Mtalii Bora as a verified local professional. Each role has its own short, step-by-step application.</p>
<div class="row g-3"><?php foreach ([['guide_signup','compass','Tour guide','Share your knowledge of Kenya\'s destinations and culture.',['Profile & specialisations','Licence and certificates','Availability calendar']],['driver_signup','truck-front','Safari driver','Offer safe, comfortable transport for safaris and transfers.',['Vehicle & driving details','PSV licence and insurance','Service areas and rates']]] as $r): ?>
<div class="col-md-6"><div class="card p-4 h-100"><i class="bi bi-<?= $r[1] ?> fs-1" style="color:var(--a)"></i><h4><?= $r[2] ?></h4><p><?= $r[3] ?></p><ul class="small"><?php foreach ($r[4] as $b) echo "<li>$b</li>"; ?></ul><a href="?p=<?= $r[0] ?>" class="btn btn-accent mt-auto align-self-start">Apply as <?= strtolower($r[2]) ?></a></div></div><?php endforeach; ?></div>
<p class="small mt-3">Already a provider? <a href="?p=login">Login</a> · All applications are reviewed by an administrator before the Verified badge appears.</p>
__MB_EOF__
mkdir -p "pages"
cat > "pages/login.php" <<'__MB_EOF__'
<div class="row justify-content-center"><div class="col-md-7 col-lg-5"><div class="card p-4"><h3>Welcome back</h3><p class="text-body-secondary small">Log in to explore Kenya with verified local experts.</p>
<?php if ($err) echo '<div class="alert alert-danger py-2">' . e($err) . '</div>'; ?>
<?= google_btn() ?><div class="text-center text-body-secondary small my-3">or log in with email</div>
<form method="post" action="?p=login"><input type="hidden" name="csrf" value="<?= e($_SESSION['csrf']) ?>"><label class="form-label">Email</label><input type="email" name="email" class="form-control mb-3" required>
<label class="form-label">Password</label><input type="password" name="password" class="form-control mb-3" required><button class="btn btn-accent w-100">Login</button></form>
<p class="small mt-3 mb-1">New here? <a href="?p=signup">Create a traveler account</a> · <a href="?p=join">Become a provider</a></p>
<div class="alert alert-secondary small mb-0 mt-2"><b>Demo logins</b> (password <code>Password123!</code>): traveler@, guide@, driver@mtalii.test · admin@mtalii.test uses <code>Admin123!</code>. The Google button is a demo until Google credentials are configured.</div></div></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/messages.php" <<'__MB_EOF__'
<h2>Messages</h2><div class="row g-3"><div class="col-md-4"><div class="list-group">
<?php foreach ([[1,'Wanjiru Kamau','Sure, 7am pickup works.'],[2,'Otieno Odhiambo','I can bring a child seat.'],[4,'Amina Hassan','Dhow trip confirmed.']] as $i => $t): ?>
<a href="#" class="list-group-item list-group-item-action <?= $i == 0 ? 'active' : '' ?>"><b><?= $t[1] ?></b><br><small><?= $t[2] ?></small></a><?php endforeach; ?></div></div>
<div class="col-md-8"><div class="card p-3"><h6>Booking #101 · Wanjiru Kamau</h6><hr><div class="bubble">Hello Sarah! Happy to guide you in the Mara on 21 Oct.</div><div class="bubble me">Great! Can we start at 7am?</div><div class="bubble">Sure, 7am pickup works.</div>
<form data-demo class="d-flex gap-2 mt-2"><input class="form-control" placeholder="Write a message" required><button class="btn btn-accent"><i class="bi bi-send"></i></button></form></div></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/notifications.php" <<'__MB_EOF__'
<h2>Notifications</h2><div class="list-group">
<?php foreach ([['calendar-check','success','Booking #102 was accepted by Otieno Odhiambo','2 hours ago'],['chat-dots','primary','New message from Wanjiru Kamau','Yesterday'],['patch-check','success','Your guide licence was verified','2 days ago'],['star','warning','Please review your trip with Amina Hassan','3 days ago'],['shield-exclamation','danger','New login from a new device','5 days ago']] as $n): ?>
<div class="list-group-item d-flex gap-3 align-items-center"><i class="bi bi-<?= $n[0] ?> text-<?= $n[1] ?> fs-4"></i><div class="flex-grow-1"><?= $n[2] ?><br><small class="text-body-secondary"><?= $n[3] ?></small></div><button class="btn btn-sm btn-outline-secondary">Mark read</button></div><?php endforeach; ?></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/pro.php" <<'__MB_EOF__'
<h2>Provider dashboard</h2><p class="text-body-secondary">Welcome, <?= e($u['name']) ?>.</p>
<div class="row row-cols-2 row-cols-lg-4 g-3 text-center mb-3 stat"><?php foreach ([['2','Pending requests'],['3','Upcoming trips'],['4.9','Average rating'],['Verified','Status']] as $s): ?><div class="col"><div class="card p-3"><b style="font-size:<?= strlen($s[0]) > 4 ? '1.4' : '2.2' ?>rem"><?= $s[0] ?></b><?= $s[1] ?></div></div><?php endforeach; ?></div>
<div class="row g-3"><div class="col-lg-8"><div class="card p-3"><h5>Booking requests</h5><table class="table align-middle mb-0"><tbody><?php foreach ($B as $b) if (in_array($b[3], ['Pending', 'Accepted'])): ?><tr><td>#<?= $b[0] ?></td><td><?= $b[2] ?></td><td><?= status_badge($b[3]) ?></td><td class="text-end"><a href="?p=bookings" class="btn btn-sm btn-outline-secondary">Manage</a></td></tr><?php endif; ?></tbody></table></div></div>
<div class="col-lg-4"><div class="card p-3"><h5>Profile checklist</h5><ul class="small mb-0"><li>✅ Account details</li><li>✅ Licence verified</li><li>⏳ Upload first-aid certificate</li><li>⬜ Set availability for next month</li></ul></div></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/provider.php" <<'__MB_EOF__'
<?php $x = prov((int)($_GET['id'] ?? 1)); $busy = []; foreach ($x[11] as $r) for ($i = $r[0]; $i <= $r[1]; $i++) $busy[date('Y-m-d', strtotime("+$i days"))] = 1;
$ym = date('Y-m'); $lead = (int)date('N', strtotime("$ym-01")) - 1; ?>
<div class="row g-3"><div class="col-lg-8"><div class="card p-4"><div class="d-flex gap-3 align-items-center"><div class="avatar" style="width:72px;height:72px;font-size:28px"><?= e($x[1][0]) ?></div>
<div><h2 class="mb-1"><?= e($x[1]) ?></h2><?= vbadge($x[6]) ?> <span class="badge text-bg-light border"><?= ucfirst($x[2]) ?></span></div></div>
<p class="mt-3"><?= e($x[9]) ?></p><ul class="list-unstyled small"><li><i class="bi bi-geo-alt"></i> <?= e($x[3]) ?> County</li><li><i class="bi bi-translate"></i> <?= e($x[4]) ?></li><li><i class="bi bi-cash"></i> $<?= $x[5] ?> per day</li>
<?php if ($x[10]) echo '<li><i class="bi bi-truck-front"></i> ' . e($x[10]) . '</li>'; ?><li><?= stars($x[7]) ?> (<?= $x[8] ?> reviews)</li></ul>
<h5>Verification</h5><ul class="small"><li><?= $x[6] ? '✅' : '⏳' ?> Identity document</li><li><?= $x[6] ? '✅' : '⏳' ?> <?= $x[2] == 'guide' ? 'Tourism guide licence' : 'PSV / driving licence' ?></li><li><?= $x[6] ? '✅' : '⏳' ?> Admin review</li></ul></div>
<div class="card p-4 mt-3" id="availability"><h5>Availability — <?= date('F Y') ?></h5><div class="cal"><?php foreach (['M','T','W','T','F','S','S'] as $h) echo "<div class='h'>$h</div>"; for ($i = 0; $i < $lead; $i++) echo "<div class='e'></div>";
for ($d = 1; $d <= (int)date('t'); $d++) { $k = date('Y-m-') . sprintf('%02d', $d); echo '<div class="' . (isset($busy[$k]) ? 'x' : '') . '">' . $d . '</div>'; } ?></div><small class="text-body-secondary">Green = available · struck-through = booked</small></div></div>
<div class="col-lg-4"><form data-demo class="card p-4"><h5>Request a booking</h5><label class="form-label small">From</label><input type="date" class="form-control mb-2" required><label class="form-label small">To</label><input type="date" class="form-control mb-2" required>
<label class="form-label small">Travelers</label><input type="number" min="1" value="2" class="form-control mb-2"><label class="form-label small">Notes</label><textarea class="form-control mb-3" rows="3" placeholder="Where would you like to go?"></textarea><button class="btn btn-accent w-100">Send request</button></form>
<div class="card p-3 mt-3"><h6>Reviews</h6><div class="small"><?= stars(5) ?> “Unforgettable trip, very knowledgeable.” — Sarah M.</div><div class="small mt-2"><?= stars(4.5) ?> “Punctual and friendly.” — Daniel K.</div></div></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/reviews.php" <<'__MB_EOF__'
<h2>Reviews & ratings</h2><div class="row g-3"><div class="col-lg-4"><div class="card p-4 text-center stat"><b>4.8</b><div><?= str_repeat('<i class="bi bi-star-fill text-warning"></i>', 5) ?></div><small class="text-body-secondary">Average from 85 reviews</small></div>
<form data-demo class="card p-3 mt-3"><h5>Leave a review</h5><label class="form-label small">Booking</label><select class="form-select mb-2"><option>#103 · Kiprono Rotich</option><option>#104 · Amina Hassan</option></select><label class="form-label small">Rating</label>
<select class="form-select mb-2"><?php for ($i = 5; $i >= 1; $i--) echo "<option>$i stars</option>"; ?></select><textarea class="form-control mb-3" rows="3" placeholder="Share your experience" required></textarea><button class="btn btn-accent w-100">Submit review</button></form></div>
<div class="col-lg-8"><?php foreach ([[5,'Sarah M.','Wanjiru made the Mara unforgettable.','Wanjiru Kamau'],[5,'Daniel K.','Amina knows Lamu inside out.','Amina Hassan'],[4,'Grace W.','Great lakes birding, a little early start!','Kiprono Rotich']] as $r): ?>
<div class="card p-3 mb-3"><div class="d-flex justify-content-between"><b><?= $r[1] ?></b><span><?= stars($r[0]) ?></span></div><p class="mb-1"><?= $r[2] ?></p><small class="text-body-secondary">Reviewed <?= $r[3] ?> · verified booking</small></div><?php endforeach; ?></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/search.php" <<'__MB_EOF__'
<?php $q = trim($_GET['q'] ?? ''); $type = $_GET['type'] ?? ''; $ver = !empty($_GET['ver']); $date = $_GET['date'] ?? ''; $max = (int)($_GET['max'] ?? 0); $svc = $_GET['svc'] ?? '';
$free = function ($b) use ($date) { if (!$date) return true; foreach ($b as $r) if ($date >= date('Y-m-d', strtotime("+$r[0] days")) && $date <= date('Y-m-d', strtotime("+$r[1] days"))) return false; return true; };
$res = array_filter($P, fn($x) => (!$type || $x[2] == $type) && (!$ver || $x[6]) && (!$max || $x[5] <= $max) && (!$svc || in_array($svc, $SVCMAP[$x[0]] ?? [])) && $free($x[11]) && (!$q || stripos("$x[1] $x[3] $x[4]", $q) !== false)); ?>
<h2><?= $type == 'driver' ? 'Safari drivers' : ($type == 'guide' ? 'Tour guides' : 'Search guides & drivers') ?></h2>
<form class="card p-3 mb-3 row g-2 align-items-end"><input type="hidden" name="p" value="search">
<div class="col-md-2"><label class="form-label small">Name, county, language</label><input name="q" value="<?= e($q) ?>" class="form-control"></div>
<div class="col-md-1"><label class="form-label small">Type</label><select name="type" class="form-select"><option value="">All</option><option value="guide" <?= $type == 'guide' ? 'selected' : '' ?>>Guides</option><option value="driver" <?= $type == 'driver' ? 'selected' : '' ?>>Drivers</option></select></div>
<div class="col-md-2"><label class="form-label small">Service</label><select name="svc" class="form-select"><option value="">Any</option><?php foreach ($SVC as $k => $v) echo "<option value=\"$k\"" . ($svc == $k ? " selected" : "") . ">" . e($v[0]) . "</option>"; ?></select></div>
<div class="col-md-2"><label class="form-label small">Available on</label><input type="date" name="date" value="<?= e($date) ?>" class="form-control"></div>
<div class="col-md-1"><label class="form-label small">Max $</label><input type="number" name="max" value="<?= $max ?: '' ?>" class="form-control"></div>
<div class="col-md-2"><label class="form-check"><input type="checkbox" name="ver" value="1" class="form-check-input" <?= $ver ? 'checked' : '' ?>> Verified only</label></div><div class="col-md-1"><button class="btn btn-accent w-100">Go</button></div></form>
<div class="row row-cols-1 row-cols-md-2 row-cols-xl-3 g-3"><?php foreach ($res as $x): ?><div class="col"><div class="card h-100 p-3"><div class="d-flex gap-3 align-items-center"><div class="avatar"><?= e($x[1][0]) ?></div>
<div><b><?= e($x[1]) ?></b><br><?= vbadge($x[6]) ?></div></div><div class="small text-body-secondary mt-2"><?= ucfirst($x[2]) ?> · <i class="bi bi-geo-alt"></i> <?= e($x[3]) ?> · $<?= $x[5] ?>/day</div>
<div class="small"><?= e($x[4]) ?></div><div class="my-1"><?php foreach ($SVCMAP[$x[0]] ?? [] as $k) echo "<span class=\"badge text-bg-light border me-1\">" . e($SVC[$k][0]) . "</span>"; ?></div><div class="my-1"><?= stars($x[7]) ?> <small>(<?= $x[8] ?>)</small></div><p class="small"><?= e($x[9]) ?></p><a href="?p=provider&id=<?= $x[0] ?>" class="mt-auto">View profile & book →</a></div></div><?php endforeach; ?></div>
<?php if (!$res) echo '<p class="text-body-secondary mt-3">No providers match those filters.</p>'; ?>
__MB_EOF__
mkdir -p "pages"
cat > "pages/security.php" <<'__MB_EOF__'
<h2>Security monitoring & audit records</h2><div class="row row-cols-2 row-cols-lg-4 g-3 text-center mb-3 stat">
<?php foreach ([['1,284','Events logged (30 days)'],['17','Failed logins'],['2','Accounts locked'],['0','Open incidents']] as $s): ?><div class="col"><div class="card p-3"><b><?= $s[0] ?></b><?= $s[1] ?></div></div><?php endforeach; ?></div>
<div class="card p-3 mb-3"><h5>Audit log</h5><div class="table-responsive"><table class="table table-sm align-middle mb-0"><thead><tr><th>Time</th><th>User</th><th>Action</th><th>IP</th><th>Result</th></tr></thead><tbody>
<?php foreach ([['09:41','admin@mtalii.test','Verified provider #4','127.0.0.1','success'],['09:12','traveler@mtalii.test','Created booking #101','127.0.0.1','success'],['08:57','unknown','Login failed (x3)','41.90.12.8','danger'],['08:30','guide@mtalii.test','Updated profile','127.0.0.1','success'],['08:02','admin@mtalii.test','Login','127.0.0.1','success']] as $r): ?>
<tr><td><?= $r[0] ?></td><td><?= $r[1] ?></td><td><?= $r[2] ?></td><td><?= $r[3] ?></td><td><span class="badge text-bg-<?= $r[4] ?>"><?= $r[4] == 'success' ? 'OK' : 'Alert' ?></span></td></tr><?php endforeach; ?></tbody></table></div></div>
<div class="card p-3"><h5>Planned security controls</h5><ul class="mb-0"><?php foreach (['Password hashing and login throttling','CSRF protection on every form','Role-based access (traveler, provider, admin)','Prepared statements and output escaping','Audit trail for sensitive actions','Security testing with OWASP ZAP and Burp Suite'] as $c) echo "<li>✅ $c</li>"; ?></ul></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/services.php" <<'__MB_EOF__'
<h2>Service categories</h2><p class="text-body-secondary">Choose the kind of experience you want, then pick a verified guide or driver offering it.</p>
<div class="row row-cols-1 row-cols-sm-2 row-cols-lg-3 g-3"><?php foreach ($SVC as $k => $v): $n = count(array_filter($SVCMAP, fn($m) => in_array($k, $m))); ?>
<div class="col"><a class="card p-4 h-100 svc" href="?p=search&svc=<?= $k ?>"><i class="bi bi-<?= $v[1] ?>"></i><h5 class="mt-2"><?= e($v[0]) ?></h5><p class="small text-body-secondary mb-2"><?= e($v[2]) ?></p><span class="badge text-bg-light border align-self-start"><?= $n ?> provider<?= $n == 1 ? '' : 's' ?></span></a></div><?php endforeach; ?></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/signup.php" <<'__MB_EOF__'
<div class="row justify-content-center"><div class="col-lg-8"><div class="card p-4"><h3>Create a traveler account</h3><?= google_btn('Sign up with Google') ?><div class="text-center text-body-secondary small my-3">or sign up with email</div>
<form data-demo class="row g-3"><?= field('Full name', 'name', 'text', 'required') . field('Email', 'email', 'email', 'required') . field('Password (8+ characters)', 'password', 'password', 'minlength=8 required') . field('Country', 'country') ?>
<div class="col-12"><label class="form-label">Interests</label><div><?php foreach ($SVC as $v): ?><label class="me-3"><input type="checkbox" class="form-check-input"> <?= e($v[0]) ?></label><?php endforeach; ?></div></div>
<div class="col-12"><button class="btn btn-accent">Create account</button> <span class="small ms-2">Already registered? <a href="?p=login">Login</a></span></div></form></div></div></div>
__MB_EOF__
mkdir -p "pages"
cat > "pages/verification.php" <<'__MB_EOF__'
<h2>Provider verification</h2><p class="text-body-secondary">How Mtalii Bora earns traveler trust: every guide and driver is reviewed by an administrator before the Verified badge appears.</p>
<div class="row g-3 mb-3"><?php foreach ([['1','Submit documents','National ID, guide or PSV licence, certificates.'],['2','Admin review','An administrator checks documents and licence numbers.'],['3','Verified badge','Badge shown on your profile and in search results.']] as $s): ?>
<div class="col-md-4"><div class="card p-3 h-100"><div class="avatar mb-2"><?= $s[0] ?></div><b><?= $s[1] ?></b><small class="text-body-secondary"><?= $s[2] ?></small></div></div><?php endforeach; ?></div>
<div class="card p-3"><h5>My documents</h5><table class="table align-middle mb-0"><thead><tr><th>Document</th><th>Status</th><th></th></tr></thead><tbody>
<?php foreach ([['National ID','Verified','success'],['Tourism guide licence (KTB)','Verified','success'],['Certificate of good conduct','Under review','warning'],['First-aid certificate','Not uploaded','secondary']] as $r): ?>
<tr><td><?= $r[0] ?></td><td><span class="badge text-bg-<?= $r[2] ?>"><?= $r[1] ?></span></td><td class="text-end"><button class="btn btn-sm btn-outline-secondary">Upload</button></td></tr><?php endforeach; ?></tbody></table></div>
<p class="small text-body-secondary mt-3">Prototype note: verification status shown here is sample data and does not represent official certification.</p>
__MB_EOF__
mkdir -p "scripts"
cat > "scripts/run.sh" <<'__MB_EOF__'
#!/usr/bin/env bash
# Optional: run without Apache — bash scripts/run.sh  →  http://localhost:8000
cd "$(dirname "$0")/.." && php -S localhost:8000
__MB_EOF__
mkdir -p "scripts"
cat > "scripts/update.sh" <<'__MB_EOF__'
#!/usr/bin/env bash
# Commit and push all changes:  bash scripts/update.sh "your message"
set -e; cd "$(dirname "$0")/.."
if [ -f .git/MERGE_HEAD ] || grep -rlE "^(<<<<<<<|>>>>>>>) " pages includes assets scripts index.php README.md 2>/dev/null; then
  echo "STOP: unresolved merge or conflict markers found. Fix them first."; exit 1
fi
MSG="${1:-Update Mtalii Bora ($(date '+%Y-%m-%d %H:%M'))}"
git add -A
if git diff --cached --quiet; then echo "No changes to commit."; else git commit -m "$MSG"; fi
git pull --rebase origin main || { echo "Pull had conflicts. Resolve them, then run again."; exit 1; }
git push -u origin main && echo "Pushed to GitHub ✔"
__MB_EOF__
printf 'Thumbs.db\n.DS_Store\n' > .gitignore
echo "Wrote $(find . -type f -not -path './.git/*' | wc -l) files."
if command -v php >/dev/null 2>&1; then
  for f in index.php includes/*.php pages/*.php; do php -l "$f" >/dev/null 2>&1 || echo "Syntax problem in $f"; done
  echo "PHP syntax check done."
fi
if [ "$PUSH" = 1 ]; then
  [ -d .git ] || git init -q
  git symbolic-ref HEAD refs/heads/main
  git config core.autocrlf false
  if git remote get-url origin >/dev/null 2>&1; then git remote set-url origin "$REPO"; else git remote add origin "$REPO"; fi
  git fetch -q origin main 2>/dev/null || echo "(remote has no main branch yet)"
  # fresh folder: sit on top of the existing GitHub history instead of creating a conflicting one
  if ! git rev-parse -q --verify HEAD >/dev/null 2>&1 && git rev-parse -q --verify origin/main >/dev/null 2>&1; then git reset -q --soft origin/main; fi
  git add -A
  if git diff --cached --quiet; then echo "Nothing new to commit."; else
    git commit -q -m "$MSG" || { echo "Git needs your identity. Run:"; echo '  git config --global user.name "Your Name"'; echo '  git config --global user.email "you@example.com"'; echo "then rerun this script with --push"; exit 1; }
  fi
  git push -u origin main && echo "Pushed to $REPO ✔" || { echo "Push failed. If it says 'fetch first', run: git pull --rebase origin main   then: git push"; exit 1; }
fi
echo "Done. Open http://localhost/mtalii-bora/ (Apache started in XAMPP)."
