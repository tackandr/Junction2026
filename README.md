# Arduino UNO Q App Lab Examples

This repository currently contains two Arduino App Lab examples for the UNO Q:

- **Blink LED** (`example_blink_led`) — a Python app calls the MCU sketch over the UNO Q Bridge to blink the built-in LED.
- **Home Climate Monitoring** (`example_climate_monitor`) — reads a Modulino Thermo, stores temperature and relative humidity samples, and serves a local chart dashboard.

The examples are complete App Lab app folders with `app.yaml`, `python/`, and `sketch/`. The climate example also includes its browser assets and uses the Web UI and time-series storage Bricks.

## Requirements

- Arduino UNO Q connected to Ubuntu over USB-C.
- `google-android-platform-tools-installer` installed on Ubuntu so the ADB tools are available.
- Arduino udev rules installed so Ubuntu can access the board over USB.
- Modulino Thermo connected to the UNO Q Qwiic connector for the climate example.

### Install ADB platform tools

```sh
sudo apt update
sudo apt install google-android-platform-tools-installer
```

Confirm Ubuntu can see the UNO Q:

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

The App Lab CLI is preinstalled on the UNO Q. These scripts copy an example from Ubuntu to `/home/arduino/ArduinoApps/`, then use `arduino-app-cli` on the board to build and start it.

## Deploy and run

From the repository directory, deploy either example:

```sh
./deploy-adb.sh blink
./deploy-adb.sh climate
```

The climate example is the default, so `./deploy-adb.sh` is equivalent to `./deploy-adb.sh climate`. Its script forwards board port 7000 to Ubuntu port 7000 and prints the dashboard URL. Open `http://localhost:7000` in a browser on Ubuntu. If that local port is occupied, choose another one, for example:

```sh
LOCAL_PORT=17000 ./deploy-adb.sh climate
```

Then open `http://localhost:17000`.

The first start can take a few minutes while the CLI prepares dependencies. The climate dashboard only works while that app is running.

## Stop an app

Stop either example by name:

```sh
./stop-adb.sh blink
./stop-adb.sh climate
```

With no argument, the stop script stops the climate example. It also removes the local port forwarding. To stop another App Lab app by its board path, pass that path instead:

```sh
./stop-adb.sh /home/arduino/ArduinoApps/another-app
```

## Initial Git push

To include these two examples and their deployment instructions without adding the separate root-level app, stage only these paths and review the result before committing:

```sh
git add README.md deploy-adb.sh stop-adb.sh example_blink_led example_climate_monitor
git status --short
```

Avoid `git add -A` for this initial push, since that would also stage unrelated root-level app changes.
