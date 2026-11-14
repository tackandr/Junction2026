# Arduino UNO Q App Lab Examples

This repository currently contains three Arduino App Lab examples for the UNO Q:

- **Blink LED** (`example_blink_led`) — a Python app calls the MCU sketch over the UNO Q Bridge to blink the built-in LED.
- **Home Climate Monitoring** (`example_climate_monitor`) — reads a Modulino Thermo, stores temperature and relative humidity samples, and serves a local chart dashboard.
- **Detect Objects on Camera** (`example_video_object_detection`) — runs the camera feed through the object detection Brick and shows live detections in a web interface.

The examples are complete App Lab app folders. The video example is Python-only and includes its browser assets; the Blink and climate examples also include MCU sketches. The climate and video examples use the Web UI Brick.

## Requirements

- Arduino UNO Q and an Ubuntu computer.
- For SSH deployment: use a private Wi-Fi hotspot (or private router) that allows connected devices to communicate. Connect both the board and computer to it; public Wi-Fi may block SSH between clients.
- For ADB deployment: the board is connected to Ubuntu over USB-C, `google-android-platform-tools-installer` is installed, and Arduino udev rules are installed.
- Modulino Thermo connected to the UNO Q Qwiic connector for the climate example.
- For video detection: Network Mode enabled on the UNO Q and a USB or CSI camera connected. A USB camera requires a powered USB-C hub.

### Connect over SSH (Wi-Fi)

The Blink example can be deployed over SSH without an ADB/USB connection. Complete the UNO Q first-time setup so SSH is enabled, and connect both the board and computer to the same private Wi-Fi hotspot. Public Wi-Fi may advertise the board through mDNS while blocking direct SSH traffic between clients. Ubuntu includes an SSH client on most installations; check with:

```sh
ssh -V
```

The SSH scripts default to `commit-and-conquer.local`, which resolves on the private hotspot used for this setup. If mDNS is unavailable, set `BOARD_HOST` to the UNO Q's current Wi-Fi IP address; you can find it in the hotspot's connected-device list.

To avoid entering the board password for each SSH login, copy your local public key to the UNO Q once. If you do not already have an SSH key, create one first:

```sh
ssh-keygen -t ed25519
```

Then copy the public key:

```sh
ssh-copy-id arduino@commit-and-conquer.local
```

If mDNS is unavailable, use the board's Wi-Fi IP instead, for example `ssh-copy-id arduino@192.168.1.42`. Accept the host key and enter the Linux password set during board setup when prompted. This adds your public key to the board's `~/.ssh/authorized_keys`, so subsequent SSH connections—including the deploy and stop scripts—can authenticate with the key. The scripts may still prompt for the Linux password when `sudo nmcli` is used to change Wi-Fi priorities.

Test the connection and leave the board shell with `exit`:

```sh
ssh arduino@commit-and-conquer.local
```

See Arduino's [UNO Q SSH guide](https://docs.arduino.cc/tutorials/uno-q/ssh/) for connection details.

### Prefer a Wi-Fi network at reconnect

UNO Q stores Wi-Fi networks as NetworkManager connection profiles. From an SSH shell on the board, list the saved profiles:

```sh
nmcli -f NAME,UUID,TYPE,DEVICE connection show
```

The SSH deploy and stop scripts can set these priorities as part of each run. Set `PREFERRED_WIFI_PROFILE` to the saved profile name for the private hotspot and, optionally, `FALLBACK_WIFI_PROFILE` to the setup-time Wi-Fi profile. Replace the sample names with exact names from the list:

```sh
PREFERRED_WIFI_PROFILE="PHONE_HOTSPOT_SSID" FALLBACK_WIFI_PROFILE="SETUP_WIFI_SSID" ./deploy-ssh.sh blink
PREFERRED_WIFI_PROFILE="PHONE_HOTSPOT_SSID" FALLBACK_WIFI_PROFILE="SETUP_WIFI_SSID" ./stop-ssh.sh blink
```

The scripts set the hotspot profile to priority 100 and the setup network to priority 0. When both networks are available, NetworkManager prefers the higher-priority profile. When either profile variable is set, the script runs `sudo nmcli` on the board and may prompt for the board's Linux password. If you want to prevent the UNO Q from reconnecting to the setup network at all, disable its autoconnect directly on the board:

```sh
sudo nmcli connection modify "SETUP_WIFI_SSID" connection.autoconnect no
```

Only disable the fallback after confirming the hotspot reconnects reliably; otherwise, the UNO Q may be left without Wi-Fi. The `arduino-app-cli system network-mode` command controls App Lab's network access, not Wi-Fi selection.

### Install ADB platform tools (USB route)

```sh
sudo apt update
sudo apt install google-android-platform-tools-installer
```

Confirm Ubuntu can see the UNO Q over USB:

```sh
adb devices -l
```

The board should appear as an authorized device.

### Fix Arduino USB permissions (udev)

Follow Arduino's [Fix udev rules on Linux](https://support.arduino.cc/hc/en-us/articles/9005041052444-Fix-udev-rules-on-Linux) instructions. From Ubuntu, download and run the official setup script:

```sh
curl -O https://content.arduino.cc/assets/arduino-udev-setup.sh
sudo bash arduino-udev-setup.sh
```

When it completes, unplug and reconnect the UNO Q so Ubuntu applies the new rules.

The App Lab CLI is preinstalled on the UNO Q. The deployment scripts copy an example to `/home/arduino/ArduinoApps/`, then use `arduino-app-cli` on the board to build and start it. The SSH scripts use the `arduino` account; set `SSH_USER` or `SSH_PORT` only if your board uses different SSH settings.

## Deploy and run

### Blink and climate over SSH

Deploy either app over the private hotspot using the default board hostname:

```sh
./deploy-ssh.sh blink
./deploy-ssh.sh climate
```

Set `BOARD_HOST=<board-ip>` if the hostname does not resolve. The climate app requires the Modulino Thermo connected to the UNO Q Qwiic connector. The deploy script transfers and starts it, then prints the dashboard URL. Open `http://commit-and-conquer.local:7000` on the same private Wi-Fi network. If you set `BOARD_HOST` to an IP address, use `http://<board-ip>:7000` instead.

Stop the apps over SSH with:

```sh
./stop-ssh.sh blink
./stop-ssh.sh climate
```

### Deploy using ADB over USB

The existing ADB route remains available when the board is connected directly to the computer over USB:

```sh
./deploy-adb.sh blink
./deploy-adb.sh climate
./deploy-adb.sh video
```

The climate example is the default, so `./deploy-adb.sh` is equivalent to `./deploy-adb.sh climate`. Climate and video both forward board port 7000 to Ubuntu and print the dashboard URL. Open `http://localhost:7000` in a browser on Ubuntu. The video example also forwards camera stream port 4912 to Ubuntu port 4912. That local port must be available. If local port 7000 is occupied, choose another dashboard port, for example:

```sh
LOCAL_PORT=17000 ./deploy-adb.sh climate
```

Then open `http://localhost:17000`. For video, run `LOCAL_PORT=17000 ./deploy-adb.sh video`; local port 4912 must also be available for its camera feed.

The first start can take a few minutes while the CLI prepares dependencies. Each web dashboard is available only while its app is running.

Enable Network Mode on the board before starting the video example if it is not already enabled. If SSH is available, run this on the board remotely:

```sh
ssh arduino@192.168.1.42 arduino-app-cli system network-mode enable
```

Replace the example IP with the UNO Q's Wi-Fi address. The ADB alternative is `adb shell arduino-app-cli system network-mode enable` when connected directly over USB.

Connect the camera before deployment. A USB camera needs a powered USB-C hub; the example also supports a CSI camera. The video app uses the `arduino:video_object_detection` and `arduino:web_ui` Bricks.

## Download climate data

With the climate app running, download recent temperature and humidity samples as JSON:

```sh
mkdir -p climate-export

curl -fsS 'http://commit-and-conquer.local:7000/get_samples/temperature/-1h/5m' \
  -o climate-export/temperature-last-hour.json

curl -fsS 'http://commit-and-conquer.local:7000/get_samples/humidity/-1h/5m' \
  -o climate-export/humidity-last-hour.json
```

The `-1h/5m` range returns five-minute averages for the last hour. To request hourly averages for the last day, change it to `-1d/1h`. For a closer-to-raw sample, use `-2m/1s`; the API returns at most 100 samples per request.

If `commit-and-conquer.local` does not resolve, replace it with the UNO Q's current Wi-Fi IP address. With the ADB deploy script's port forwarding active, use `http://localhost:7000` as the base URL instead. The same endpoint also supports `dew_point`, `heat_index`, and `absolute_humidity` as measurement names.

## Stop an app

Stop an example by name:

```sh
./stop-adb.sh blink
./stop-adb.sh climate
./stop-adb.sh video
```

For Blink or climate deployed over Wi-Fi, use `./stop-ssh.sh blink` or `./stop-ssh.sh climate`; the SSH script defaults to `commit-and-conquer.local` and accepts a `BOARD_HOST` override.

With no argument, the stop script stops the climate example. It also removes the local port forwarding. To stop another App Lab app by its board path, pass that path instead:

```sh
./stop-adb.sh /home/arduino/ArduinoApps/another-app
```
