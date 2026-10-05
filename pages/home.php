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
