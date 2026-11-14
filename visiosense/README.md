# VisioSense

VisioSense captures a still image from the first USB camera every five seconds and displays the latest image in a local web UI.

## How it works

- The Python app continuously reads frames from Arduino's `Camera` peripheral so older camera runtimes do not leave the app displaying stale buffered frames.
- Frames are captured at 1920×1080 and encoded as JPEG at quality 85.
- Each capture atomically replaces `data/latest.jpg`; image history is not retained.
- The app sends a small WebSocket notification after each capture. The browser then fetches the JPEG from `/latest.jpg`.
- Saving snapshots begins when the first browser connects to the web UI. The camera is read continuously, and the latest frame is saved every five seconds while the app runs.

The capture resolution and interval are constants near the top of `python/main.py` and can be adjusted. For the Arduino USB Camera, the requested resolution can be changed to 3840×2160 if full 4K images are needed and supported by the installed camera stack.

## Run on the UNO Q

Connect the USB camera through the powered USB-C hub and deploy over the private Wi-Fi network:

```sh
./deploy-ssh.sh visiosense
```

Open `http://commit-and-conquer.local:7000` on the same network. The current JPEG is also served at `http://commit-and-conquer.local:7000/latest.jpg` and is stored on the board at `/home/arduino/ArduinoApps/visiosense/data/latest.jpg`.

Stop it with:

```sh
./stop-ssh.sh visiosense
```
