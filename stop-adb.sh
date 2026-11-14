#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-climate}"
LOCAL_PORT="${LOCAL_PORT:-7000}"

case "$APP_NAME" in
  blink)
    APP_TARGET="/home/arduino/ArduinoApps/example-blink-led"
    ;;
  climate)
    APP_TARGET="/home/arduino/ArduinoApps/home-climate-monitoring-and-storage"
    ;;
  *)
    APP_TARGET="$APP_NAME"
    ;;
esac

if ! command -v adb >/dev/null 2>&1; then
  echo "Error: adb was not found. Install Android platform-tools on Ubuntu first." >&2
  exit 1
fi

if ! adb get-state >/dev/null 2>&1; then
  echo "Error: no single authorized ADB device is available. Check 'adb devices -l'." >&2
  exit 1
fi

adb forward --remove "tcp:$LOCAL_PORT" >/dev/null 2>&1 || true
adb shell arduino-app-cli app stop "$APP_TARGET"
echo "Stopped app: $APP_TARGET"
