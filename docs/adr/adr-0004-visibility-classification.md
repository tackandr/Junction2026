# ADR-0004: Classify Demo Visibility from Detected Proxies

- **Status:** Proposed
- **Date:** 2026-11-14
- **Decision makers:** Project Team
- **Technical area:** Visibility classification
- **Related issues:** N/A
- **Supersedes:** N/A
- **Superseded by:** N/A

## Context and Problem Statement

The demo uses a mock scene with a cup and a bottle as proxies for landmarks at ordered distances from the camera. The cup is nearer and represents the 500 m threshold; the bottle is farther and represents the 1000 m threshold. The system needs to convert object detection results from each captured image into one visibility estimate for the demo display.

The mock props do not represent calibrated real-world distances. The displayed values are demo categories derived from the thresholds, not meteorological measurements. Object detections and confidence scores are produced by the `arduino:object_detection` Brick selected in [ADR-0003](adr-0003-still-image-object-detection-brick.md).

## Decision Drivers

- Classify each image independently so the output reflects the current capture.
- Ignore low-confidence detections using a defined confidence threshold.
- Use the furthest qualifying proxy detected to determine the estimate.
- Return one meter value that can be displayed by the demo.
- Make clear that the values are mockup outputs, not calibrated observations.

## Considered Options

1. **Furthest detected proxy per image:** Use the farthest proxy with a qualifying detection to select the estimate for that image.
2. **Nearest missing proxy:** Base the estimate on the first expected proxy that is not detected.
3. **Temporal aggregation:** Combine detections across multiple images before producing an estimate.

## Decision Outcome

**Chosen option:** Furthest detected proxy per image, represented by its lower-bound demo value

**Rationale:** The furthest qualifying proxy detected provides the demo's visibility category for the current image. The cup marks the 500 m boundary and the bottle marks the 1000 m boundary. Using the lower bound gives the requested single meter value without inventing precision within a category. A successful inference with no qualifying proxy returns the lower category value, 0 m. Capture or inference failure remains `unknown`.

| Qualifying detections in the image | Demo range represented | Returned estimate |
| --- | --- | ---: |
| Neither cup nor bottle | `[0, 500)` m | 0 m |
| Cup, without bottle | `[500, 1000)` m | 500 m |
| Bottle, with or without cup | `[1000, ∞)` m | 1000 m |

A proxy detection qualifies when its confidence is greater than or equal to `0.5`. The rules apply independently to each image; results from different images are not combined.

### Positive Consequences

- Produces one predictable meter value for every successful image inference.
- Makes the mapping from the detected proxies to the demo output straightforward to explain.
- Avoids implying finer precision than the mock scene and thresholds support.

### Negative Consequences and Trade-offs

- The displayed estimate is a representative lower-bound demo value, not a measured visibility distance.
- A missed detection can lower the estimate even when the proxy is visible to a person.
- Independent per-image results may fluctuate between captures as detection results vary.

## Options Analysis

| Option | Benefits | Drawbacks | Notes |
| --- | --- | --- | --- |
| Furthest detected proxy per image | Simple mapping; uses the strongest distance evidence in the current image. | Sensitive to missed or inconsistent detections. | Selected; confidence must be at least 0.5. |
| Nearest missing proxy | Can express an upper bound from the first proxy not detected. | Does not follow the agreed rule that the furthest detected object counts; detection errors can overstate the bound. | Not selected. |
| Temporal aggregation | Can reduce fluctuations between captures. | Adds delay and state across images, contrary to independent per-image classification. | Not selected. |

## Implementation Notes

- [ ] Configure the cup and bottle labels as the demo proxies and associate them with the 500 m and 1000 m boundaries.
- [ ] Apply the `confidence >= 0.5` qualification rule before selecting the furthest detected proxy.
- [ ] Return 0, 500, or 1000 meters for successful inference according to the mapping above; return `unknown` when capture or inference fails.
- [ ] Label the displayed values as demo estimates and avoid presenting them as calibrated meteorological measurements.
- [ ] Validate the mapping using images with neither proxy, the cup only, the bottle only, and both proxies.

## Validation and Review

- **Success criteria:** Each successful image maps to the expected demo value for the qualifying proxy detections, including the bottle-only case; detections below 0.5 confidence do not count; capture or inference failure returns `unknown`.
- **Review date or trigger:** Review after integrating the classifier with the mock scene, or before using the output as a real-world visibility measurement.

## References

- [ADR-0003: Select the Still-Image Object Detection Brick](adr-0003-still-image-object-detection-brick.md)
- [ADR-0002: Data Storage Architecture](adr-0002-data-storage.md)

## Change History

| Date | Change | Author |
| --- | --- | --- |
| 2026-11-14 | Initial proposal | Project Team |
