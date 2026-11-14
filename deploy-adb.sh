#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE="${1:-climate}"
LOCAL_PORT="${LOCAL_PORT:-7000}"
NEEDS_SKETCH=true
NEEDS_ASSETS=false

case "$EXAMPLE" in
  blink)
    APP_SOURCE="$SCRIPT_DIR/example_blink_led"
    APP_DIR="/home/arduino/ArduinoApps/example-blink-led"
    ;;
  climate)
    APP_SOURCE="$SCRIPT_DIR/example_climate_monitor"
    APP_DIR="/home/arduino/ArduinoApps/home-climate-monitoring-and-storage"
    NEEDS_ASSETS=true
    ;;
  video)
    APP_SOURCE="$SCRIPT_DIR/example_video_object_detection"
    APP_DIR="/home/arduino/ArduinoApps/video-generic-object-detection"
    NEEDS_SKETCH=false
    NEEDS_ASSETS=true
    ;;
  *)
    echo "Usage: $0 [blink|climate|video]" >&2
    exit 2
    ;;
esac

if [[ "$EXAMPLE" == "video" && "$LOCAL_PORT" == "4912" ]]; then
  echo "Error: LOCAL_PORT cannot be 4912 because the video stream uses that local port." >&2
  exit 2
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "Error: adb was not found. Install Android platform-tools on Ubuntu first." >&2
  exit 1
fi

if ! adb get-state >/dev/null 2>&1; then
  echo "Error: no single authorized ADB device is available. Check 'adb devices -l'." >&2
  exit 1
fi

if [[ ! -f "$APP_SOURCE/app.yaml" || ! -f "$APP_SOURCE/python/main.py" ]]; then
  echo "Error: expected App Lab example files under $APP_SOURCE." >&2
  exit 1
fi
if [[ "$NEEDS_SKETCH" == "true" && ( ! -f "$APP_SOURCE/sketch/sketch.ino" || ! -f "$APP_SOURCE/sketch/sketch.yaml" ) ]]; then
  echo "Error: expected sketch files under $APP_SOURCE/sketch." >&2
  exit 1
fi
if [[ "$NEEDS_ASSETS" == "true" && ! -f "$APP_SOURCE/assets/index.html" ]]; then
  echo "Error: expected web assets under $APP_SOURCE/assets." >&2
  exit 1
fi

echo "Copying the $EXAMPLE example to the UNO Q..."
adb shell "mkdir -p '$APP_DIR'"
adb push "$APP_SOURCE/app.yaml" "$APP_DIR/"
if [[ -f "$APP_SOURCE/README.md" ]]; then
  adb push "$APP_SOURCE/README.md" "$APP_DIR/"
fi
adb push "$APP_SOURCE/python" "$APP_DIR/"
if [[ "$NEEDS_SKETCH" == "true" ]]; then
  adb push "$APP_SOURCE/sketch" "$APP_DIR/"
fi
if [[ "$NEEDS_ASSETS" == "true" ]]; then
  adb push "$APP_SOURCE/assets" "$APP_DIR/"
fi
adb shell "chown -R arduino:arduino '$APP_DIR'"
echo "Starting the $EXAMPLE example..."
adb shell arduino-app-cli app start "$APP_DIR"
adb forward --remove "tcp:$LOCAL_PORT" >/dev/null 2>&1 || true
adb forward --remove tcp:4912 >/dev/null 2>&1 || true
if [[ "$EXAMPLE" == "climate" || "$EXAMPLE" == "video" ]]; then
  if ! adb forward "tcp:$LOCAL_PORT" tcp:7000; then
    echo "The app started, but port forwarding failed. If local port $LOCAL_PORT is busy, retry with LOCAL_PORT=17000." >&2
    exit 1
  fi
  echo "Dashboard: http://localhost:$LOCAL_PORT"
  if [[ "$EXAMPLE" == "video" ]]; then
    if ! adb forward tcp:4912 tcp:4912; then
      echo "The app started, but camera stream port 4912 could not be forwarded. Close anything using local port 4912 and retry." >&2
      exit 1
    fi
    echo "Camera stream forwarded on localhost:4912."
  fi
else
  echo "Blink is running on the UNO Q."
fi
