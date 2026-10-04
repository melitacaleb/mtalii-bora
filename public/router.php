<?php
// Dev router: php -S localhost:8000 -t public public/router.php
$p = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if (str_starts_with($p, '/api/')) { require __DIR__ . '/../server/app.php'; return true; }
if ($p !== '/' && file_exists(__DIR__ . $p)) return false;
readfile(__DIR__ . '/index.html');
