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
$need += ['services' => $all, 'search' => $all, 'provider' => $all]; // guests are sent to traveler login/sign-up first
if (!$u && in_array($p, ['services', 'search', 'provider'], true)) {
  $_SESSION['next'] = $p . (isset($_GET['svc'], $SVC[$_GET['svc']]) ? '&svc=' . $_GET['svc'] : '') . ($p == 'provider' ? '&id=' . (int)($_GET['id'] ?? 1) : '') . (in_array($_GET['type'] ?? '', ['guide', 'driver'], true) ? '&type=' . $_GET['type'] : '');
}
if (isset($need[$p]) && (!$u || !in_array($u['role'], $need[$p]))) go('login');
function after_login($role) { global $landing; $n = $_SESSION['next'] ?? null; unset($_SESSION['next']); go($n ?: $landing[$role]); }
if ($p === 'home' && $u) go($landing[$u['role']]);
$err = '';
if ($p === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
  $em = strtolower(trim($_POST['email'] ?? '')); $acc = $USERS[$em] ?? null;
  if (!hash_equals($_SESSION['csrf'], $_POST['csrf'] ?? '')) $err = 'Session expired. Please try again.';
  elseif (!$acc || !hash_equals($acc[2], $_POST['password'] ?? '')) $err = 'Invalid email or password.';
  else { session_regenerate_id(true); $_SESSION['user'] = ['name' => $acc[0], 'email' => $em, 'role' => $acc[1]]; after_login($acc[1]); }
}
if ($p === 'google') { // DEMO: real Google OAuth needs a Google Cloud client ID/secret (see README)
  session_regenerate_id(true); $_SESSION['user'] = ['name' => 'Google Traveler', 'email' => 'demo.google@gmail.com', 'role' => 'traveler']; after_login('traveler');
}
if ($p === 'logout') { $_SESSION = []; session_destroy(); go('login'); }
require __DIR__ . '/includes/header.php';
require __DIR__ . "/pages/$p.php";
require __DIR__ . '/includes/footer.php';
