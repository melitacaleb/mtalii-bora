<?php $cat = $_GET['cat'] ?? ''; $list = array_filter($D, fn($d) => !$cat || $d[2] == $cat); ?>
<h2>Destinations across Kenya</h2><p class="text-body-secondary"><?= count($D) ?> places in <?= count(array_unique(array_column($D, 1))) ?> counties.</p>
<div class="mb-3 d-flex gap-2 flex-wrap"><a class="btn btn-sm <?= $cat ? 'btn-outline-secondary' : 'btn-success' ?>" href="?p=destinations">All</a>
<?php foreach (array_keys($CAT) as $c): ?><a class="btn btn-sm <?= $cat == $c ? 'btn-success' : 'btn-outline-secondary' ?>" href="?p=destinations&cat=<?= $c ?>"><?= $CAT[$c][2] . ' ' . $c ?></a><?php endforeach; ?></div>
<div class="row row-cols-1 row-cols-sm-2 row-cols-xl-4 g-3"><?php foreach ($list as $d) echo dcard($d); ?></div>
