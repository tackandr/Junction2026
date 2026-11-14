# VisioSense Object Detection

An Arduino UNO Q app that captures one still image from a USB webcam when requested, runs the built-in object-detection Brick, and shows the result in a local web page. The captured and annotated images remain in memory and are not written to disk.

The app uses Arduino's bundled pretrained COCO model. It reports the model's common object labels with bounding boxes; landmark-specific classes such as towers and forest edges are not included in that model.

## App files

- `app.yaml` declares the `web_ui` and `object_detection` Bricks.
- `python/main.py` captures the newest frame from the first USB webcam and runs detection.
- `assets/` contains the local capture and result page.

## Run on the UNO Q

Connect a USB/UVC webcam to the UNO Q and deploy this directory using the manual ADB workflow in [ADR-0001](../../docs/adr/adr-0001-hardware-and-development-workflow.md). After the app starts, open `http://<UNO-Q-IP-ADDRESS>:7000` in a browser on the same network and select **Capture & detect**.

The app requires the board's Arduino App runtime and Docker services used by the declared Bricks. The first app start may need network access to prepare Brick images and model assets.
