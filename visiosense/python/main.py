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

from arduino.app_bricks.dbstorage_tsstore import TimeSeriesStore
from arduino.app_bricks.object_detection import ObjectDetection
from arduino.app_bricks.web_ui import WebUI
from arduino.app_peripherals.camera import Camera
from arduino.app_utils import App

CAPTURE_INTERVAL_SECONDS = 5
CAMERA_RESOLUTION = (1920, 1080)
CAMERA_FPS = 10
JPEG_QUALITY = 85
DETECTION_CONFIDENCE = 0.35

APP_DIRECTORY = Path(__file__).resolve().parents[1]
DATA_DIRECTORY = APP_DIRECTORY / "data"
LATEST_IMAGE_PATH = DATA_DIRECTORY / "latest.jpg"
TEMP_IMAGE_PATH = DATA_DIRECTORY / "latest.jpg.tmp"

DATA_DIRECTORY.mkdir(parents=True, exist_ok=True)

ui = WebUI()
db = TimeSeriesStore()
object_detection = None
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


def on_get_samples(resource: str, start: str, aggr_window: str):
    samples = db.read_samples(
        measure=resource,
        start_from=start,
        aggr_window=aggr_window,
        aggr_func="mean",
        limit=100,
    )
    return [{"ts": sample[1], "value": sample[2]} for sample in samples]


ui.expose_api(
    "GET",
    "/get_samples/{resource}/{start}/{aggr_window}",
    on_get_samples,
)


def record_visibility(distance_m, timestamp_ms=None):
    if timestamp_ms is None:
        timestamp_ms = int(time.time() * 1000)

    value = float(distance_m)
    try:
        db.write_sample("visibility_in_air", value, timestamp_ms)
    except Exception as error:
        print("Could not store visibility sample: %s" % error)

    ui.send_message("visibility", {"value": value, "ts": timestamp_ms})
    print("Estimated visibility: %s m" % value)


def estimate_visibility_distance(detections):
    visible_classes = {
        detection["class_name"].strip().lower()
        for detection in detections
        if detection.get("class_name")
    }

    # Visibility is set by the furthest recognized landmark. A bottle alone
    # therefore gives 1000 m, even if the nearer cup was missed.
    if "bottle" in visible_classes:
        return 1000
    if "cup" in visible_classes:
        return 500
    return 0


def detect_objects(jpeg_bytes, captured_at):
    global object_detection

    try:
        if object_detection is None:
            object_detection = ObjectDetection()
        result = object_detection.detect(
            jpeg_bytes,
            confidence=DETECTION_CONFIDENCE,
        )
        detections = []
        if isinstance(result, dict):
            for item in result.get("detection", []):
                class_name = item.get("class_name")
                bounding_box = item.get("bounding_box_xyxy")
                if not class_name or not isinstance(bounding_box, (list, tuple)) or len(bounding_box) != 4:
                    continue
                try:
                    box = [int(round(float(value))) for value in bounding_box]
                    confidence = float(item.get("confidence", 0.0))
                except (TypeError, ValueError):
                    continue
                detections.append(
                    {
                        "class_name": str(class_name),
                        "confidence": confidence,
                        "bounding_box_xyxy": box,
                    }
                )

        distance_m = estimate_visibility_distance(detections)
        record_visibility(distance_m, captured_at["ts"])
        ui.send_message(
            "detection_result",
            {
                "captured_at": captured_at["iso"],
                "detections": detections,
                "visibility_distance_m": distance_m,
            },
        )
        print("Object detection found %s object(s)." % len(detections))
    except Exception as error:
        message = str(error)
        print("Object detection failed: %s" % message)
        record_visibility(0, captured_at["ts"])
        ui.send_message(
            "detection_error",
            {"captured_at": captured_at["iso"], "message": message},
        )


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
            capture_time = datetime.now(timezone.utc)
            captured_at = {
                "iso": capture_time.isoformat(timespec="milliseconds"),
                "ts": int(capture_time.timestamp() * 1000),
            }
            snapshot = {
                "captured_at": captured_at["iso"],
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
            detect_objects(encoded_jpeg.tobytes(), captured_at)
            next_snapshot_at = now + CAPTURE_INTERVAL_SECONDS

        except Exception as error:
            message = str(error)
            print("Camera capture failed: %s" % message)
            with state_lock:
                latest_error = message
            record_visibility(0)
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
