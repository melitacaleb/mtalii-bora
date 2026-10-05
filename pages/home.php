<section class="hero"><small class="text-uppercase">Explore Kenya</small><h1>Kenya's marketplace for trusted local travel experts</h1>
<p class="lead" style="max-width:540px">Book verified tour guides and safari drivers, plan your itinerary together, and travel with confidence — from the Mara to the coast.</p>
<div class="d-flex gap-2 flex-wrap mt-2"><a class="btn btn-accent btn-lg" href="?p=signup">Create traveler account</a><a class="btn btn-light btn-lg rounded-pill" href="?p=login">Login</a></div></section>

<section class="my-5"><div class="text-center mb-4"><h2>Join Mtalii Bora</h2><p class="text-body-secondary">Choose how you want to use the platform.</p></div>
<div class="row g-3"><?php foreach ([['person','Traveler','Discover and book verified guides and drivers, chat, and plan your trip.',['Search and compare providers','Book and manage trips','Shared itinerary planner'],'Create account','?p=signup','Already registered? <a href="?p=login">Login</a>'],
['compass','Tour guide','Share your knowledge of Kenya and reach international visitors.',['Professional profile and reviews','Verified badge','Control your availability'],'Apply as a guide','?p=guide_signup','Takes about 5 minutes'],
['truck-front','Safari driver','Offer safe, comfortable transport for safaris and transfers.',['Vehicle and licence verification','Booking requests in one place','Set service areas and rates'],'Apply as a driver','?p=driver_signup','Takes about 5 minutes']] as $a): ?>
<div class="col-md-4"><div class="card aud p-4 h-100"><i class="bi bi-<?= $a[0] ?>"></i><h4 class="mt-2"><?= $a[1] ?></h4><p class="text-body-secondary"><?= $a[2] ?></p><ul class="small"><?php foreach ($a[3] as $b) echo "<li>$b</li>"; ?></ul>
<a class="btn btn-accent mt-auto align-self-start" href="<?= $a[5] ?>"><?= $a[4] ?></a><small class="text-body-secondary mt-2"><?= $a[6] ?></small></div></div><?php endforeach; ?></div></section>

<section class="my-5" id="services"><div class="d-flex justify-content-between align-items-end flex-wrap gap-2"><div><h2 class="mb-0">Our services</h2><p class="text-body-secondary mb-0">Pick a category — we'll ask you to log in or sign up first.</p></div></div>
<div class="row row-cols-1 row-cols-sm-2 row-cols-lg-3 g-3 mt-1"><?php foreach ($SVC as $k => $v): ?><div class="col"><a class="card p-4 h-100 svc" href="?p=search&svc=<?= $k ?>"><i class="bi bi-<?= $v[1] ?>"></i><h5 class="mt-2"><?= e($v[0]) ?></h5><p class="small text-body-secondary mb-2"><?= e($v[2]) ?></p><span class="small text-decoration-underline align-self-start">Explore →</span></a></div><?php endforeach; ?></div>
<h5 class="mt-4">Coming soon</h5><div class="row row-cols-2 row-cols-lg-4 g-3"><?php foreach ([['building','Accommodation'],['ticket-perforated','Park & event tickets'],['car-front','Car hire'],['shield-check','Travel insurance']] as $c): ?>
<div class="col"><div class="card soon p-3 text-center"><i class="bi bi-<?= $c[0] ?> fs-3"></i><b><?= $c[1] ?></b><span class="badge text-bg-secondary mx-auto mt-1">Coming soon</span></div></div><?php endforeach; ?></div></section>

<section class="my-5 text-center"><h2>How it works</h2><div class="row row-cols-2 row-cols-lg-4 g-3 mt-1">
<?php foreach ([['Create an account','Sign up free as a traveler.'],['Find a verified expert','Filter by service, county, language and availability.'],['Book and chat','Send a request and agree the details.'],['Plan your trip','Build a day-by-day itinerary together.']] as $i => $s): ?>
<div class="col"><div class="step-n"><?= $i + 1 ?></div><b><?= $s[0] ?></b><br><small class="text-body-secondary"><?= $s[1] ?></small></div><?php endforeach; ?></div></section>

<div class="d-flex justify-content-between align-items-baseline"><h2>Popular destinations</h2><a href="?p=destinations">View all →</a></div>
<div class="row row-cols-1 row-cols-sm-2 row-cols-xl-4 g-3"><?php foreach (array_slice($D, 0, 4) as $d) echo dcard($d); ?></div>
<div class="row row-cols-2 row-cols-md-4 g-3 text-center my-4">
<?php foreach ([[count($D),'Destinations'],[count(array_unique(array_column($D, 1))),'Counties'],[count($P),'Providers'],[count(array_filter($P, fn($x) => $x[6])),'Verified']] as $s): ?>
<div class="col"><div class="card stat p-3"><b><?= $s[0] ?></b><?= $s[1] ?></div></div><?php endforeach; ?></div>
<div class="cta"><h2>Your next Kenyan adventure starts here</h2><p>Create a free account in minutes.</p><a class="btn btn-accent" href="?p=signup">Get started</a></div>
