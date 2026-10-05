<h2>Messages</h2><div class="row g-3"><div class="col-md-4"><div class="list-group">
<?php foreach ([[1,'Wanjiru Kamau','Sure, 7am pickup works.'],[2,'Otieno Odhiambo','I can bring a child seat.'],[4,'Amina Hassan','Dhow trip confirmed.']] as $i => $t): ?>
<a href="#" class="list-group-item list-group-item-action <?= $i == 0 ? 'active' : '' ?>"><b><?= $t[1] ?></b><br><small><?= $t[2] ?></small></a><?php endforeach; ?></div></div>
<div class="col-md-8"><div class="card p-3"><h6>Booking #101 · Wanjiru Kamau</h6><hr><div class="bubble">Hello Sarah! Happy to guide you in the Mara on 21 Oct.</div><div class="bubble me">Great! Can we start at 7am?</div><div class="bubble">Sure, 7am pickup works.</div>
<form data-demo class="d-flex gap-2 mt-2"><input class="form-control" placeholder="Write a message" required><button class="btn btn-accent"><i class="bi bi-send"></i></button></form></div></div></div>
