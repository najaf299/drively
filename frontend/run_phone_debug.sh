#!/usr/bin/env bash
# Run Drivly on a connected iPhone in DEBUG mode (hot reload when the debugger attaches).
#
# On this Mac (Xcode 15.2) + iOS 26 devices, Flutter often cannot attach the debugger,
# so hot reload may not work — use ./run_sim.sh for reliable hot reload, or ./run_phone.sh
# for release installs on the physical phone.
#
# Requirements: iPhone + Mac on the SAME Wi-Fi, backend: cd backend && composer serve:lan
set -e

IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
if [ -z "$IP" ]; then
  echo "Could not detect a Wi-Fi IP. Are you connected to Wi-Fi?" >&2
  exit 1
fi

echo "Using Mac IP: $IP"
echo "Backend: cd backend && composer serve:lan"
echo ""
echo "Debug mode — press r = hot reload, R = hot restart, q = quit (if debugger attaches)."
echo "If the app installs but 'flutter run' never connects, use ./run_sim.sh or ./run_phone.sh"
echo ""

flutter run \
  --dart-define=API_URL=http://$IP:8000/api/v1 \
  --dart-define=WS_HOST=$IP \
  "$@"
