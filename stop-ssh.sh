#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-blink}"
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

case "$APP_NAME" in
  blink)
    APP_DIR="/home/arduino/ArduinoApps/example-blink-led"
    APP_LABEL="Blink"
    ;;
  climate)
    APP_DIR="/home/arduino/ArduinoApps/home-climate-monitoring-and-storage"
    APP_LABEL="Home Climate Monitoring"
    ;;
  video)
    APP_DIR="/home/arduino/ArduinoApps/video-generic-object-detection"
    APP_LABEL="Detect Objects on Camera"
    ;;
  *)
    echo "Usage: BOARD_HOST=<board-ip-or-hostname> $0 [blink|climate|video]" >&2
    exit 2
    ;;
esac

SSH_TARGET="$SSH_USER@$BOARD_HOST"

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

echo "Stopping $APP_LABEL on $SSH_TARGET..."
set_wifi_priorities
ssh -p "$SSH_PORT" "$SSH_TARGET" "arduino-app-cli app stop '$APP_DIR'"
echo "Stopped $APP_LABEL on the UNO Q."
