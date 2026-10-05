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
