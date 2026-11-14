"""Capture a webcam image on request and return its detected objects."""

import base64
import io
import logging

import cv2
from PIL import Image, ImageDraw, ImageFont

from arduino.app_bricks.object_detection import ObjectDetection
from arduino.app_bricks.web_ui import WebUI
from arduino.app_peripherals.camera import Camera
from arduino.app_utils import App

CAMERA_SOURCE = "usb:0"
CAMERA_RESOLUTION = (640, 480)
CAMERA_FPS = 10

logger = logging.getLogger("visiosense")
object_detection = ObjectDetection()
web_ui = WebUI()


def _capture_image() -> Image.Image:
    """Capture the newest frame from the first USB camera."""
    with Camera(
        CAMERA_SOURCE,
        resolution=CAMERA_RESOLUTION,
        fps=CAMERA_FPS,
    ) as camera:
        frame = camera.capture(latest=True)

    if frame is None:
        raise RuntimeError("The webcam did not return an image.")

    # V4L USB frames are OpenCV BGR arrays; Pillow expects RGB channel order.
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    return Image.fromarray(rgb_frame)


def _draw_detections(
    image: Image.Image,
    detections: list[dict],
) -> Image.Image:
    """Draw labels and boxes without exposing confidence scores."""
    annotated = image.copy()
    draw = ImageDraw.Draw(annotated)
    font = ImageFont.load_default()

    for detection in detections:
        box = detection.get("bounding_box_xyxy")
        label = detection.get("class_name")
        if not box or not label:
            continue

        left, top, right, bottom = (int(round(value)) for value in box)
        draw.rectangle((left, top, right, bottom), outline="#00a8a8", width=3)

        text_bounds = draw.textbbox((0, 0), label, font=font)
        text_width = text_bounds[2] - text_bounds[0]
        text_height = text_bounds[3] - text_bounds[1]
        text_top = max(0, top - text_height - 8)
        draw.rectangle(
            (left, text_top, left + text_width + 10, text_top + text_height + 6),
            fill="#00a8a8",
        )
        draw.text((left + 5, text_top + 3), label, fill="white", font=font)

    return annotated


def _encode_jpeg(image: Image.Image) -> str:
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=88)
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def capture_and_detect():
    """Capture and classify one frame; keep image data in memory only."""
    try:
        image = _capture_image()
        result = object_detection.detect(image)
        detections = (result or {}).get("detection", [])
        annotated = _draw_detections(image, detections)

        return {
            "success": True,
            "image": _encode_jpeg(annotated),
            "detections": [
                {"label": item["class_name"]}
                for item in detections
                if item.get("class_name")
            ],
            "count": len(detections),
        }
    except Exception as error:
        logger.exception("Capture or object detection failed")
        return {"success": False, "error": str(error)}


web_ui.expose_api("POST", "/capture", capture_and_detect)

App.run()
