# Mtalii Bora — PHP + Bootstrap prototype (no database yet)
Put this folder at C:\xampp\htdocs\mtalii-bora, start Apache, open http://localhost/mtalii-bora/ (or: bash scripts/run.sh -> http://localhost:8000).

## Demo logins (sessions only, no DB)
traveler@mtalii.test / guide@mtalii.test / driver@mtalii.test -> Password123!   |   admin@mtalii.test -> Admin123!
Each role lands on its own page with its own sidebar; protected pages redirect to login.

## Continue with Google (demo button for now)
Real sign-in needs a Google Cloud OAuth client (console.cloud.google.com > APIs & Services > Credentials).
Add redirect URI http://localhost/mtalii-bora/index.php?p=google, then implement the OAuth code flow in the google handler in index.php.
