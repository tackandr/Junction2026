# 💡 Brainstorming Ideas

> **Goal:** Generate, explore, evaluate, and organize ideas.

**Date:** YYYY-MM-DD  
**Project/Topic:** [Enter topic]  
**Participants:** [Names]  
**Status:** 🟡 In Progress

---

## 🎯 1. Define the Challenge

### Problem Statement
The world is facing a new technological revolution around the new AI tools, where LLM and other AI technologies are rapidly changing the way we work, we communicate, we create and we solve problems.

Soon the Robots will be smarter than ever and Physical AI will be running in every small appliance and device.

It looks like America and Asia are taking the lead on this revolution and big companies from both continents will control, for good and for bad, these AI tools.

They tell you that the future is inevitable, but it is not true. Europe can change that!

Using Edge AI devices like the Arduino UNO Q we can create local solutions to local problems that are not dependant on governments or private companies. Most of these problems will have a huge impact in the environment having the opportunity to create step by step a Greener, high-technological and human Europe: The Green European Renaissance.

### Key Questions
- What are we trying to achieve?
- Who will benefit?
- What constraints do we have?
- What would success look like?

---

## 🌱 2. Brainstorm Ideas

### Idea 1: 🌫️ VisioSense — AI-Powered Local Visibility Monitoring

#### 1. How your idea could work

Imagine installing a camera overlooking a landscape with several recognizable landmarks.

| Landmark | Distance | Detection result |
|---|---:|---|
| Building A | 200 m | ✅ Visible |
| Church tower | 500 m | ✅ Visible |
| Forest edge | 1,000 m | ✅ Visible |
| Communication tower | 2,000 m | ❌ Not visible |
| Distant hill | 5,000 m | ❌ Not visible |

The system would estimate:

**Visibility: approximately 1–2 km**

This is a simplified estimate based on which landmarks are recognizable. The actual meteorological optical range (MOR) requires more careful calibration.

##### The processing pipeline

**Step 1 — Camera installation**

Install a fixed camera with a view of multiple objects at known distances.

**Step 2 — Landmark identification**

During clear weather, identify landmarks and assign their distances.

For example:
- Building: 200 m
- Forest: 800 m
- Tower: 1,500 m
- Hill: 4,000 m

**Step 3 — AI-based recognition**

The Arduino UNO Q periodically captures images.

A lightweight computer vision model determines whether each landmark can still be recognized.

**Step 4 — Visibility estimation**

The software estimates visibility from the detection results.

A more advanced implementation would also analyze image contrast instead of relying only on binary detection.

**Step 5 — Local reporting**

The device produces outputs such as:

> 🌫️ Estimated visibility: 850 m  
> Visibility trend: Decreasing  
> Conditions: Possible fog  
> Confidence: Moderate

These values would be estimates, not certified meteorological observations.

---

#### 2. Does this already exist?

**Yes. The principle is established, but that doesn't invalidate the project.**

I found three particularly relevant references.

##### 🇳🇱 KNMI — Camera-Based Visibility Estimation

The Royal Netherlands Meteorological Institute published a feasibility study investigating visibility estimation from camera images.

One approach is called *landmark discrimination*.

It determines visibility by identifying objects at known distances and evaluating whether they remain visible.

This is extremely close to your idea. [KNMI](https://cdn.knmi.nl/knmi/pdf/bibliotheek/knmipubIR/IR2015-05.pdf?utm_source=chatgpt.com)


##### 🇸🇰 Camera-Based Visibility for Aviation

A 2022 study investigated machine-learning-based fog nowcasting using camera observations.

Researchers used landmarks at known distances to estimate visibility around an airport.

They also examined nighttime visibility using distant lights. [MDPI](https://www.mdpi.com/2073-4433/13/10/1684?utm_source=chatgpt.com)


##### 🇨🇿 AI Landmark Recognition for Visibility Estimation

A 2023 paper titled *Application of K-Nearest Neighbor Classification for Static Webcams Visibility Observation* studied automatic visibility estimation using landmark identification.

This is particularly relevant because it investigates automating the same process a human meteorological observer performs. [DOI](https://doi.org/10.1155/2023%2F6285569?utm_source=chatgpt.com)


**Conclusion:** The scientific concept is not new. The opportunity is to develop an affordable, fully autonomous implementation using an Arduino UNO Q.

---

#### 3. How to make it innovative

I see three particularly interesting directions.

##### A. Self-Calibrating Visibility Sensor

**The problem:** Traditional landmark-based camera systems generally require manual identification of landmarks and their distances.

**Your innovation:** An Edge AI system that simplifies installation.

For example:

1. Install the camera.
2. Capture an image during clear weather.
3. Automatically identify potential landmarks.
4. Associate landmarks with distances using terrain information or a user-confirmed map.
5. Monitor their visibility continuously.

This would make deployment easier for municipalities, weather enthusiasts, and local communities.

Automatic distance estimation would be one of the more difficult components, so I would make it a stretch goal rather than part of the initial prototype.

##### B. Visibility Measurements Where Weather Stations Don't Exist

Traditional visibility sensors can be expensive and require dedicated infrastructure.

Your solution could provide supplementary observations in locations such as:

- Rural roads vulnerable to fog.
- Small harbors.
- Remote communities.
- Mountain valleys.
- Agricultural areas.

A decentralized network of inexpensive visibility monitors could improve local awareness of rapidly changing conditions.

**This aligns particularly well with the challenge's European technological independence theme.**

##### C. Explainable AI Visibility Monitoring

This is probably my favorite direction.

Instead of a neural network simply predicting:

> Visibility = 1,200 meters

Your system could explain its prediction:

> Building at 500 m: detected  
> Forest at 1,000 m: detected  
> Tower at 1,500 m: not detected  
> Estimated visibility: 1,000–1,500 m

This is an important advantage.

The output is understandable, verifiable, and can be inspected by a human observer.

---

#### 4. Can Arduino UNO Q Actually Do This?

**Yes.**

Arduino confirms that the UNO Q supports USB webcams, Python, Linux applications, and lightweight AI processing. [Arduino Official Store](https://store.arduino.cc/products/uno-q?utm_source=chatgpt.com)

A practical architecture could be:

| Component | Purpose |
|---|---|
| Arduino UNO Q | Main processing device |
| USB camera | Captures the landscape |
| Lightweight AI model | Identifies landmarks |
| OpenCV | Analyzes contrast and image quality |
| Temperature/humidity sensor | Provides additional environmental context |
| Local web dashboard | Displays estimated visibility |
| Optional Wi-Fi/LoRa | Shares visibility measurements |

##### One important technical decision

I would **not start with a general-purpose object detector like YOLO**.

Instead, because the camera is fixed, you already know where each landmark should appear.

You can define regions of interest for each landmark and use a combination of:

- Image similarity against clear-weather references.
- Edge detection.
- Local contrast measurements.
- A small neural network that classifies landmark visibility.

This would be computationally efficient and potentially more reliable than repeatedly detecting generic objects.

A small AI model could also distinguish between three states:

**Visible / Obscured / Uncertain**

The uncertain category is important because snow, darkness, camera contamination, and illumination changes can make landmarks difficult to recognize even when atmospheric visibility is good.

---

#### 5. The Scientific Challenge: Detection ≠ Meteorological Visibility

There is one issue I would pay particular attention to.

**The fact that an AI model recognizes a building does not necessarily mean a human observer could recognize it under the standard meteorological visibility definition.**

An AI system might recognize a building even when its contrast is extremely low.

Conversely, it might fail to detect a building because of poor lighting.

Meteorological optical range is based on atmospheric extinction, conventionally using a 5% transmission threshold. [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S1352231018304679?utm_source=chatgpt.com)

Therefore, I would recommend combining:

**Landmark detection + contrast analysis + calibration**

And validating your estimates against measurements from an established visibility sensor.

This would give your project a stronger scientific foundation.

---

#### 6. How I Would Demonstrate It at a Hackathon

You could create a miniature landscape.

Position several small landmark models at different distances from the camera.

Then introduce artificial fog using a small fog machine.

As fog increases, the system would identify fewer landmarks and display the changing visibility category.

For example:

| Scenario | Expected output |
|---|---|
| Clear conditions | All landmarks visible |
| Light artificial fog | Distant landmarks obscured |
| Dense artificial fog | Only nearby landmarks visible |
| Fog dissipating | Visibility improving |

The demo would illustrate the detection principle, although distances in a miniature scene would not directly translate into real atmospheric visibility.

### Idea 2: [Idea Name]
**Description:**  
[Describe the idea]

**Potential Benefits:**
- Benefit 1
- Benefit 2

**Challenges:**
- Challenge 1

### Idea 3: [Idea Name]
**Description:**  
[Describe the idea]

---

## 🚀 3. Wild Ideas

*Think beyond current limitations.*

- 💡 What if we had unlimited resources?
- 💡 What if we started from scratch?
- 💡 What would an unconventional solution look like?
- 💡 What could we automate?
- 💡 What would make this 10× better?

**Ideas:**
1. [Wild idea]
2. [Wild idea]
3. [Wild idea]

---

## 🧩 4. Group Similar Ideas

### Category A: [Name]
- Idea 1
- Idea 2

### Category B: [Name]
- Idea 3
- Idea 4

### Category C: [Name]
- Idea 5
- Idea 6

---

## 📊 5. Evaluate Ideas

Score each idea from 1 (low) to 5 (high).

| Idea | Impact | Feasibility | Creativity | Priority |
|------|--------|-------------|------------|----------|
| Idea 1 | 5 | 4 | 3 | High |
| Idea 2 | 4 | 5 | 4 | High |
| Idea 3 | 3 | 2 | 5 | Medium |
| Idea 4 | 2 | 3 | 4
