# VisioSense

VisioSense captures a still image from the first USB camera every five seconds, runs object detection on it, reads the Modulino Thermo, and displays the latest image and sensor charts in a local web UI.

## How it works

- The Python app continuously reads frames from Arduino's `Camera` peripheral so older camera runtimes do not leave the app displaying stale buffered frames.
- Frames are captured at 1920×1080 and encoded as JPEG at quality 85.
- The `arduino:object_detection` Brick analyzes each saved JPEG. Results include the class string, confidence, and bounding-box coordinates in pixel format `[x1, y1, x2, y2]`.
- A bottle detection maps to 1000 m; otherwise a cup detection maps to 500 m; if neither appears, the estimate is 0 m. If both appear, the bottle's 1000 m distance wins. A bottle by itself also maps to 1000 m because it is the furthest visible landmark.
- The estimate is stored persistently in the `visibility_in_air` time-series measurement, in meters. Camera-capture and object-detection failures are recorded as 0 m.
- The MCU sketch reads the Modulino Thermo once per second and sends temperature and relative humidity over the Bridge. Both are stored in the same `TimeSeriesStore` as `temperature` (°C) and `humidity` (%).
- Each capture atomically replaces `data/latest.jpg`; image history is not retained.
- The browser fetches the JPEG from `/latest.jpg`, displays the detections and visibility estimate, and plots visibility, temperature, and humidity. The time-series measurements persist; image history does not.
- Saving snapshots begins when the first browser connects to the web UI. The camera is read continuously, and the latest frame is saved every five seconds while the app runs.

The capture resolution, interval, and detection confidence are constants near the top of `python/main.py` and can be adjusted. For the Arduino USB Camera, the requested resolution can be changed to 3840×2160 if full 4K images are needed and supported by the installed camera stack.

## Run on the UNO Q

Connect the USB camera through the powered USB-C hub and deploy over the private Wi-Fi network:

```sh
./deploy-ssh.sh visiosense
```

Connect the Modulino Thermo to the UNO Q Qwiic connector and the USB camera through the powered USB-C hub. Open `http://commit-and-conquer.local:7000` on the same network. The current JPEG is also served at `http://commit-and-conquer.local:7000/latest.jpg` and is stored on the board at `/home/arduino/ArduinoApps/visiosense/data/latest.jpg`.

Visibility history is available through the same shape as the climate app's time-series API:

```text
http://commit-and-conquer.local:7000/get_samples/visibility_in_air/-1h/1m
```

The temperature and humidity use the same endpoint and format:

```text
http://commit-and-conquer.local:7000/get_samples/temperature/-1h/1m
http://commit-and-conquer.local:7000/get_samples/humidity/-1h/1m
```

Stop it with:

```sh
./stop-ssh.sh visiosense
```
