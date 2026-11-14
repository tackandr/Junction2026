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

### Positive Consequences

- Detection results include the object tag, bounding box, and confidence needed by downstream processing.
- The Brick's still-image input matches the planned capture workflow.
- The decision keeps object detection on the edge device within the Arduino App Lab Brick architecture.

### Negative Consequences and Trade-offs

- The still-image Brick's availability and behavior must be confirmed on the target UNO Q App Lab installation.
- The detection model's supported labels and performance may limit which configured landmarks it can recognize.
- This Brick choice alone does not establish that an AI detection indicates meteorological visibility; that inference requires a separate strategy and validation.

## Options Analysis

| Option | Benefits | Drawbacks | Notes |
| --- | --- | --- | --- |
| `arduino:image_classification` | Returns image-level class confidence. | Does not locate objects or return bounding boxes. | Does not meet the per-object data requirement. |
| `arduino:object_detection` | Accepts a still image and returns classes, boxes, and confidence values. | Requires checking model and Brick support on the target device. | Selected. |
| `arduino:video_object_detection` | Designed for continuous camera streams and detection callbacks. | Its live-stream workflow does not match discrete still-image input as directly. | The repository README references this Brick for a separate video example. |

## Implementation Notes

- [ ] Confirm `arduino:object_detection` is available for the target UNO Q and App Lab version.
- [ ] Confirm the Brick accepts the captured still-image format and exposes each detection's tag, bounding box, and confidence score.
- [ ] Record the selected object detection model and its supported labels in the implementation documentation.
- [ ] Keep image disposal and detection-result retention behavior consistent with the surrounding system design.

## Validation and Review

- **Success criteria:** A captured still image can be passed to `arduino:object_detection`, and the returned results include a tag, bounding box, and confidence score for each detected object.
- **Review date or trigger:** Review after the first on-device integration, or if the selected Brick or model is unavailable or cannot provide the required result fields.

## References

- [Arduino App Lab AI models and Bricks documentation](https://docs.arduino.cc/software/app-lab/integrations/ai-models/)
- [Arduino object detection Brick example](https://github.com/arduino/app-bricks-examples/tree/main/inspirational/common/object-detection)
- [ADR-0001: Hardware specifications](adr-0001-hardware-specifications.md)

## Change History

| Date | Change | Author |
| --- | --- | --- |
| 2026-11-14 | Initial proposal | Project team |
