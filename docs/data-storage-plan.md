# 📊 Data Storage Plan: VisioSense

## 1. Goal
Define a robust, efficient, and scalable data storage architecture for the VisioSense environmental monitoring app. The system must handle diverse data types (time-series telemetry, AI-driven visibility metrics, and visual evidence) while operating within the hardware constraints of the Arduino UNO Q.

---

## 2. Data Classification
We categorize the data into three distinct streams based on their volume, frequency, and purpose.

### A. Telemetry (Time-Series)
*   **Description:** Continuous readings from environmental sensors.
*   **Data Points:** Temperature, Relative Humidity, Light Level.
*   **Characteristics:** High frequency (e.g., every 1–60 seconds), low volume per sample.
*   **Priority:** High for trend analysis.

### B. Visibility Metrics (AI-Derived)
*   **Description:** Results from the AI visibility pipeline.
*   **Data Points:** 
    *   `visibility_estimate`: Estimated Meteorological Optical Range (MOR).
    *   `confidence_score`: AI's confidence in the estimate.
    *   `landmark_status`: A bitmask or JSON object representing which landmarks were detected (e.g., `{ "BuildingA": visible, "ChurchTower": obscured }`).
*   **Characteristics:** Medium frequency (triggered by camera capture), medium volume.
*   **Priority:** Critical for the core application value.

### C. Visual Evidence (Blobs)
*   **Description:** Images used for AI processing and human verification.
*   **Data Points:** Full-frame captures, cropped landmark regions.
*   **Characteristics:** Low frequency, high volume.
*   **Priority:** Medium (essential for "Explainable AI" but storage-expensive).

---

## 3. Proposed Storage Architecture

### 3.1. Primary Storage: `TimeSeriesStore` (The "Brick")
Following the pattern in `example_climate_monitor`, we will utilize the `arduino.app_bricks.dbstorage_tsstore.TimeSeriesStore`.
*   **Usage:** All Telemetry and Visibility Metrics will be written as samples.
*   **Why:** It provides built-in time-series management and aggregation (mean, max, min), which is ideal for dashboarding.
*   **Schema:** `db.write_sample(measure_name, value, timestamp)`

### 3.2. Evidence Storage: File System
Since `TimeSeriesStore` is for scalar values, image data will be stored directly on the Linux filesystem.
*   **Path:** `/home/arduino/ArduinoApps/visiosense/evidence/`
*   **Naming Convention:** `YYYYMMDD_HHMMSS_status.jpg`
*   **Linking:** The `TimeSeriesStore` entry for a visibility event will contain the filename of the corresponding image as a metadata tag or a separate "pointer" sample.

---

## 4. Data Lifecycle & Management

### 4.1. Retention Policy
To prevent flash memory exhaustion:
*   **Telemetry:** Keep raw samples for 7 days $\rightarrow$ Aggregate to hourly means for 30 days $\rightarrow$ Delete.
*   **Visibility Metrics:** Keep raw samples for 30 days.
*   **Visual Evidence:** Store only "Change Events" (e.g., when visibility drops by >10%) and a daily baseline image. Delete others after 48 hours.

### 4.2. Flash Wear Mitigation
*   **Batch Writing:** Group sensor updates to reduce write cycles.
*   **Circular Buffers:** Implement fixed-size directories for evidence to automatically overwrite the oldest images.

---

## 5. Integration with Web UI
The storage will be exposed via the `WebUI` brick:
*   **API Endpoint:** `GET /get_samples/{resource}/{start}/{window}`
*   **Image Endpoint:** `GET /evidence/{filename}`
*   **Explainability View:** A combined endpoint that returns the visibility estimate AND the status of individual landmarks used to calculate it.
