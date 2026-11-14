# VisioSense — 3-minute presentation speaker notes

**Target audience:** Hackathon judges and technically curious non-specialists  
**Target duration:** 180 seconds  
**Slide format:** 16:9, eight slides

## Slide 1 — Visibility changes everything (00:00–00:15)

When visibility falls unexpectedly, transport slows and safety margins shrink. Yet many local conditions are not observed in detail. VisioSense explores a practical question: can an affordable edge device turn a camera view into useful visibility information?

## Slide 2 — Visibility affects safety and mobility (00:15–00:40)

Fog can limit airport capacity, delay flights, and sometimes lead to diversions. At sea, reduced visibility can disrupt port operations and raise collision or grounding risks. On roads, it means lower speeds and greater collision risk. Haze can accompany poor air quality, but visibility alone cannot measure pollution.

## Slide 3 — Local visibility can change between stations (00:40–01:00)

Traditional visibility instruments are specialized and can be costly to deploy and maintain. Many places therefore have sparse local observations, even though fog can change quickly over short distances. VisioSense asks whether a simpler camera-based station can add useful local observations.

## Slide 4 — A small station. Processing stays local. (01:00–01:20)

The prototype pairs a fixed USB camera and Modulino Thermo with an Arduino UNO Q. While the app is running, it captures a still about every five seconds and performs object detection locally. Temperature and relative humidity add environmental context.

## Slide 5 — Known landmarks turn images into distance evidence (01:20–01:45)

With a fixed view and landmarks at known distances, detections can indicate how far visibility extends. As fog thickens, distant landmarks may disappear. These generated images illustrate the idea, not detector results. Real-world estimates would need stable framing, calibration, and validation.

## Slide 6 — The furthest detected proxy sets the demo value (01:45–02:20)

In our mock-up, the cup is nearer and the bottle farther. We classify each image independently: no qualifying proxy maps to 0 m, cup without bottle maps to 500 m, and any bottle detection maps to 1000 m. These are lower-bound demo values, not real-world measurements: the props do not sit at those distances. Lighting and contrast can also affect detection.

## Slide 7 — Visibility with environmental context (02:20–02:40)

The app time-stamps visibility estimates with temperature and relative humidity readings. Visibility is stored in meters; sensor values use degrees Celsius and percent. These records make local trends available for review. This slide shows field names only, not invented readings.

## Slide 8 — More local observations. Better questions. (02:40–03:00)

The opportunity is a more accessible source of local observations. Over time, a network of affordable edge devices could help communities understand where and when visibility changes. Those records could support future research into forecasting, but forecasting is not implemented in this prototype. VisioSense: see further, understand better.

## Visual and source notes

- The airport, harbor, road, and city images are project-provided promotional illustrations, not documentary evidence or prototype footage.
- The clear-to-fog sequence on slide 5 uses the generated images in `generated_data/`. It is illustrative and is not a detector result or calibrated visibility reading.
- The sparse-observation network on slide 3 and distributed network on slide 8 are conceptual diagrams, not maps of real stations or deployments.
- No third-party images, measured demonstration values, cost figures, or meteorological accuracy claims are included.
