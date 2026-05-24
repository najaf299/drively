#!/usr/bin/env bash
# Run Drivly on the iOS Simulator. The simulator shares the Mac's network, so it
# always uses localhost — this works on ANY Wi-Fi with zero config changes.
#
# Requirements: a booted Simulator (open -a Simulator) and the backend running
#   php artisan serve            # localhost is enough for the simulator
set -e

flutter run \
  --dart-define=API_URL=http://localhost:8000/api/v1 \
  --dart-define=WS_HOST=localhost \
  "$@"
