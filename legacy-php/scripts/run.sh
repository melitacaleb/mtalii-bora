#!/usr/bin/env bash
# Optional: run without Apache — bash scripts/run.sh  →  http://localhost:8000
cd "$(dirname "$0")/.." && php -S localhost:8000
