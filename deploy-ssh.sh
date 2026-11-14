#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE="${1:-blink}"
BOARD_HOST="${BOARD_HOST:-commit-and-conquer.local}"
SSH_USER="${SSH_USER:-arduino}"
SSH_PORT="${SSH_PORT:-22}"
PREFERRED_WIFI_PROFILE="${PREFERRED_WIFI_PROFILE:-}"
FALLBACK_WIFI_PROFILE="${FALLBACK_WIFI_PROFILE:-}"

if [[ -n "$PREFERRED_WIFI_PROFILE" && "$PREFERRED_WIFI_PROFILE" == "$FALLBACK_WIFI_PROFILE" ]]; then
  echo "Error: preferred and fallback Wi-Fi profiles must be different." >&2
  exit 2
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "Error: ssh was not found. Install Ubuntu's OpenSSH client (openssh-client)." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "Error: tar was not found on this computer." >&2
  exit 1
fi

NEEDS_ASSETS=false
NEEDS_SKETCH=true
case "$EXAMPLE" in
  blink)
    APP_SOURCE="$SCRIPT_DIR/example_blink_led"
    APP_DIR="/home/arduino/ArduinoApps/example-blink-led"
    APP_LABEL="Blink"
    ;;
  climate)
    APP_SOURCE="$SCRIPT_DIR/example_climate_monitor"
    APP_DIR="/home/arduino/ArduinoApps/home-climate-monitoring-and-storage"
    APP_LABEL="Home Climate Monitoring"
    NEEDS_ASSETS=true
    ;;
  video)
    APP_SOURCE="$SCRIPT_DIR/example_video_object_detection"
    APP_DIR="/home/arduino/ArduinoApps/video-generic-object-detection"
    APP_LABEL="Detect Objects on Camera"
    NEEDS_ASSETS=true
    NEEDS_SKETCH=false
    ;;
  visiosense)
    APP_SOURCE="$SCRIPT_DIR/visiosense"
    APP_DIR="/home/arduino/ArduinoApps/visiosense"
    APP_LABEL="VisioSense"
    NEEDS_ASSETS=true
    NEEDS_SKETCH=false
    ;;
  *)
    echo "Usage: BOARD_HOST=<board-ip-or-hostname> $0 [blink|climate|video|visiosense]" >&2
    exit 2
    ;;
esac

SSH_TARGET="$SSH_USER@$BOARD_HOST"

check_video_network_mode() {
  local status

  if ! status=$(ssh -p "$SSH_PORT" "$SSH_TARGET" "arduino-app-cli system network-mode status"); then
    echo "Error: could not check Network Mode on $SSH_TARGET." >&2
    return 1
  fi

  status="${status,,}"
  if [[ "$status" == *disabled* ]]; then
    echo "Error: Network Mode is disabled on the UNO Q." >&2
    echo "Enable it once from an interactive terminal, then rerun this script:" >&2
    echo "  ssh -t -p $SSH_PORT $SSH_TARGET arduino-app-cli system network-mode enable" >&2
    return 1
  fi

  if [[ "$status" == *enabled* ]]; then
    echo "Network Mode is already enabled."
    return 0
  fi

  echo "Error: unexpected Network Mode status from $SSH_TARGET: $status" >&2
  return 1
}

set_wifi_priorities() {
  local remote_command=""
  local quoted_profile

  if [[ -n "$PREFERRED_WIFI_PROFILE" ]]; then
    printf -v quoted_profile '%q' "$PREFERRED_WIFI_PROFILE"
    remote_command="sudo nmcli connection modify $quoted_profile connection.autoconnect yes connection.autoconnect-priority 100"
  fi

  if [[ -n "$FALLBACK_WIFI_PROFILE" ]]; then
    printf -v quoted_profile '%q' "$FALLBACK_WIFI_PROFILE"
    if [[ -n "$remote_command" ]]; then
      remote_command+=" && "
    fi
    remote_command+="sudo nmcli connection modify $quoted_profile connection.autoconnect yes connection.autoconnect-priority 0"
  fi

  if [[ -n "$remote_command" ]]; then
    echo "Setting Wi-Fi autoconnect priorities on $SSH_TARGET..."
    ssh -t -p "$SSH_PORT" "$SSH_TARGET" "$remote_command"
  fi
}

if [[ ! -f "$APP_SOURCE/app.yaml" || ! -f "$APP_SOURCE/python/main.py" ]]; then
  echo "Error: expected App Lab files under $APP_SOURCE." >&2
  exit 1
fi
if [[ "$NEEDS_SKETCH" == "true" && ( ! -f "$APP_SOURCE/sketch/sketch.ino" || ! -f "$APP_SOURCE/sketch/sketch.yaml" ) ]]; then
  echo "Error: expected MCU sketch files under $APP_SOURCE/sketch." >&2
  exit 1
fi
if [[ "$NEEDS_ASSETS" == "true" && ! -f "$APP_SOURCE/assets/index.html" ]]; then
  echo "Error: expected web assets under $APP_SOURCE/assets." >&2
  exit 1
fi

APP_PATHS=(app.yaml)
if [[ -f "$APP_SOURCE/README.md" ]]; then
  APP_PATHS+=(README.md)
fi
APP_PATHS+=(python)
if [[ "$NEEDS_SKETCH" == "true" ]]; then
  APP_PATHS+=(sketch)
fi
if [[ "$NEEDS_ASSETS" == "true" ]]; then
  APP_PATHS+=(assets)
fi

echo "Sending the $APP_LABEL example to $SSH_TARGET:$APP_DIR and starting it..."
set_wifi_priorities
if [[ "$EXAMPLE" == "video" ]]; then
  echo "Checking Network Mode for video detection..."
  check_video_network_mode
fi
REMOTE_COMMAND="mkdir -p '$APP_DIR' && tar -xzf - -C '$APP_DIR' && arduino-app-cli app start '$APP_DIR'"
tar -czf - -C "$APP_SOURCE" "${APP_PATHS[@]}" | ssh -p "$SSH_PORT" -T "$SSH_TARGET" "$REMOTE_COMMAND"
if [[ "$EXAMPLE" == "climate" || "$EXAMPLE" == "video" || "$EXAMPLE" == "visiosense" ]]; then
  echo "Dashboard: http://$BOARD_HOST:7000"
  if [[ "$EXAMPLE" == "video" ]]; then
    echo "Camera stream: http://$BOARD_HOST:4912/embed"
  fi
elif [[ "$EXAMPLE" == "blink" ]]; then
  echo "Blink is running on the UNO Q."
fi
