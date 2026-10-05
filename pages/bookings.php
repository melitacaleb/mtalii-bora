<?php $tab = $_GET['tab'] ?? 'active'; $rows = array_filter($B, fn($b) => $tab == 'history' ? in_array($b[3], ['Completed', 'Cancelled']) : in_array($b[3], ['Pending', 'Accepted'])); ?>
<h2><?= $tab == 'history' ? 'Booking history' : 'Booking management' ?></h2>
<ul class="nav nav-tabs mb-3"><li class="nav-item"><a class="nav-link <?= $tab != 'history' ? 'active' : '' ?>" href="?p=bookings">Active</a></li><li class="nav-item"><a class="nav-link <?= $tab == 'history' ? 'active' : '' ?>" href="?p=bookings&tab=history">History</a></li></ul>
<div class="card"><div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th>#</th><th>Provider</th><th>Dates</th><th>Total</th><th>Status</th><th></th></tr></thead><tbody>
<?php foreach ($rows as $b): $pv = prov($b[1]); ?><tr><td><?= $b[0] ?></td><td><a href="?p=provider&id=<?= $pv[0] ?>"><?= e($pv[1]) ?></a></td><td><?= $b[2] ?></td><td>$<?= $b[4] ?></td><td><?= status_badge($b[3]) ?></td>
<td class="text-end"><form data-demo class="d-inline"><?php if ($b[3] == 'Pending'): ?><button class="btn btn-sm btn-success">Accept</button> <button class="btn btn-sm btn-outline-danger">Reject</button>
<?php elseif ($b[3] == 'Accepted'): ?><a href="?p=itinerary" class="btn btn-sm btn-outline-secondary">Itinerary</a> <button class="btn btn-sm btn-outline-danger">Cancel</button>
<?php elseif ($b[3] == 'Completed'): ?><a href="?p=reviews" class="btn btn-sm btn-outline-secondary">Review</a><?php endif; ?></form></td></tr><?php endforeach; ?></tbody></table></div></div>
