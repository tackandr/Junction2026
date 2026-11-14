# SPDX-FileCopyrightText: Copyright (C) Arduino s.r.l. and/or its affiliated companies
#
# SPDX-License-Identifier: MPL-2.0

import os
import threading
import time
from datetime import datetime, timezone
from pathlib import Path

import cv2
from fastapi.responses import FileResponse, Response

from arduino.app_bricks.web_ui import WebUI
from arduino.app_peripherals.camera import Camera
from arduino.app_utils import App

CAPTURE_INTERVAL_SECONDS = 5
CAMERA_RESOLUTION = (1920, 1080)
CAMERA_FPS = 10
JPEG_QUALITY = 85

APP_DIRECTORY = Path(__file__).resolve().parents[1]
DATA_DIRECTORY = APP_DIRECTORY / "data"
LATEST_IMAGE_PATH = DATA_DIRECTORY / "latest.jpg"
TEMP_IMAGE_PATH = DATA_DIRECTORY / "latest.jpg.tmp"

DATA_DIRECTORY.mkdir(parents=True, exist_ok=True)

ui = WebUI()
state_lock = threading.Lock()
thread_lock = threading.Lock()
stop_event = threading.Event()
capture_thread = None
latest_snapshot = None
latest_error = None


def get_latest_image():
    if not LATEST_IMAGE_PATH.is_file():
        return Response(
            content=b"No camera image has been captured yet.",
            status_code=503,
            media_type="text/plain",
        )

    return FileResponse(
        LATEST_IMAGE_PATH,
        media_type="image/jpeg",
        headers={"Cache-Control": "no-store"},
    )


ui.expose_api("GET", "/latest.jpg", get_latest_image)


def capture_images():
    global latest_snapshot, latest_error

    camera = None
    next_snapshot_at = 0.0

    while not stop_event.is_set():
        try:
            if camera is None:
                camera = Camera(
                    "usb:0",
                    resolution=CAMERA_RESOLUTION,
                    fps=CAMERA_FPS,
                )
                camera.start()
                next_snapshot_at = time.monotonic()

            # Keep reading frames continuously. Some UNO Q camera runtimes do
            # not support capture(latest=True), and a camera read left idle for
            # five seconds can otherwise return an old buffered frame.
            frame = camera.capture()
            if frame is None:
                raise RuntimeError("The camera returned no frame.")

            now = time.monotonic()
            if now < next_snapshot_at:
                continue

            encoded_ok, encoded_jpeg = cv2.imencode(
                ".jpg",
                frame,
                [int(cv2.IMWRITE_JPEG_QUALITY), JPEG_QUALITY],
            )
            if not encoded_ok:
                raise RuntimeError("Could not encode the camera frame as JPEG.")

            TEMP_IMAGE_PATH.write_bytes(encoded_jpeg.tobytes())
            os.replace(TEMP_IMAGE_PATH, LATEST_IMAGE_PATH)

            height, width = frame.shape[:2]
            snapshot = {
                "captured_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "width": int(width),
                "height": int(height),
            }
            with state_lock:
                latest_snapshot = snapshot
                latest_error = None

            ui.send_message("snapshot", snapshot)
            print(
                "Captured %sx%s JPEG at %s"
                % (width, height, snapshot["captured_at"])
            )
            next_snapshot_at = now + CAPTURE_INTERVAL_SECONDS

        except Exception as error:
            message = str(error)
            print("Camera capture failed: %s" % message)
            with state_lock:
                latest_error = message
            ui.send_message("camera_error", {"message": message})

            if camera is not None:
                try:
                    camera.stop()
                except Exception as stop_error:
                    print("Could not stop camera cleanly: %s" % stop_error)
                camera = None
            stop_event.wait(CAPTURE_INTERVAL_SECONDS)

    if camera is not None:
        camera.stop()


def on_ui_connect(session_id):
    global capture_thread

    with state_lock:
        snapshot = latest_snapshot
        error = latest_error

    if snapshot is not None:
        ui.send_message("snapshot", snapshot, room=session_id)
    elif error is not None:
        ui.send_message("camera_error", {"message": error}, room=session_id)

    with thread_lock:
        if capture_thread is None or not capture_thread.is_alive():
            capture_thread = threading.Thread(
                target=capture_images,
                name="VisioSenseCameraCapture",
                daemon=True,
            )
            capture_thread.start()


ui.on_connect(on_ui_connect)

print("Starting VisioSense...")
App.run()
stop_event.set()
