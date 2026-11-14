# ADR-0003: Select the Still-Image Object Detection Brick

- **Status:** Proposed
- **Date:** 2026-11-14
- **Decision makers:** Project team
- **Technical area:** Edge image processing
- **Related issues:** None
- **Supersedes:** None
- **Superseded by:** None

## Context and Problem Statement

The edge device will capture a still image every five seconds and run object detection on it. The selected Arduino Brick must identify objects and provide a bounding box, tag, and confidence score for each detection. Later processing will use detections of configured landmarks to estimate visibility; that processing strategy is outside this ADR.

The hardware specifications are recorded separately in [ADR-0001](adr-0001-hardware-specifications.md). Images will be discarded after inference, while detection results are retained. If the device cannot produce a usable result, the visibility output will be unknown. These behaviors provide context and are not decisions made by this ADR.

## Decision Drivers

- Return a bounding box for each detected object.
- Return an object tag and confidence score with each detection.
- Accept a still image captured by the edge device as input.
- Fit the Arduino UNO Q App Lab Brick architecture.

## Considered Options

1. **`arduino:image_classification`:** Classifies the image as a whole and returns class confidence, without object locations.
2. **`arduino:object_detection`:** Runs detection on an input image and returns object classes, bounding boxes, and confidence values.
3. **`arduino:video_object_detection`:** Detects objects from a live video stream and provides detection callbacks.

## Decision Outcome

**Chosen option:** `arduino:object_detection`

**Rationale:** The still-image object detection Brick accepts an image directly and provides the per-object location and confidence data required by later landmark processing. Image classification does not provide bounding boxes. The video object detection Brick targets a live stream, while this system captures discrete still images.
| Date | Change | Author |
| --- | --- | --- |
| 2026-11-14 | Initial proposal | Project team |
