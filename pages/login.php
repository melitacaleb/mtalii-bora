<div class="row justify-content-center"><div class="col-md-7 col-lg-5"><div class="card p-4"><h3>Welcome back</h3><?php if (!empty($_SESSION['next'])): ?><div class="alert alert-info py-2 small">Please log in — or <a href="?p=signup">create a free traveler account</a> — to continue.</div><?php endif; ?><p class="text-body-secondary small">Log in to explore Kenya with verified local experts.</p>
<?php if ($err) echo '<div class="alert alert-danger py-2">' . e($err) . '</div>'; ?>
<?= google_btn() ?><div class="text-center text-body-secondary small my-3">or log in with email</div>
<form method="post" action="?p=login"><input type="hidden" name="csrf" value="<?= e($_SESSION['csrf']) ?>"><label class="form-label">Email</label><input type="email" name="email" class="form-control mb-3" required>
<label class="form-label">Password</label><input type="password" name="password" class="form-control mb-3" required><button class="btn btn-accent w-100">Login</button></form>
<p class="small mt-3 mb-1">New here? <a href="?p=signup">Create a traveler account</a> · <a href="?p=join">Become a provider</a></p>
<div class="alert alert-secondary small mb-0 mt-2"><b>Demo logins</b> (password <code>Password123!</code>): traveler@, guide@, driver@mtalii.test · admin@mtalii.test uses <code>Admin123!</code>. The Google button is a demo until Google credentials are configured.</div></div></div></div>
