#!/usr/bin/env bash
# Run Drivly on a connected iPhone WITHOUT editing any Dart config.
#
# It auto-detects your Mac's current Wi-Fi IP every run, so when you switch
# Wi-Fi networks you just run this again — no more editing app_config.dart.
#
# Requirements: iPhone + Mac on the SAME Wi-Fi, and the backend started with
#   php artisan serve --host=0.0.0.0
set -e

# Detect the active LAN IP (Wi-Fi en0, then wired/en1 as a fallback).
IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
if [ -z "$IP" ]; then
  echo "Could not detect a Wi-Fi IP. Are you connected to Wi-Fi?" >&2
  exit 1
fi

echo "Using Mac IP: $IP"
echo "Make sure the backend is running:  php artisan serve --host=0.0.0.0"
echo ""

flutter run \
  --dart-define=API_URL=http://$IP:8000/api/v1 \
  --dart-define=WS_HOST=$IP \
  "$@"
