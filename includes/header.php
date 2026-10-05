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
