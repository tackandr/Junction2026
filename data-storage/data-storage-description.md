# 🛠️ Data Storage Reference (Developer & AI Guide)

This document serves as the technical source of truth for the VisioSense data storage layer. It is designed for AI agents and developers to ensure consistent data access and storage patterns.

---

## 1. Storage Architecture Overview

The system uses a hybrid storage approach to balance the need for fast time-series queries and high-volume binary data (images).

| Data Type | Storage Mechanism | Location / Tool | Purpose |
| :--- | :--- | :--- | :--- |
| **Telemetry & Metrics** | `TimeSeriesStore` | `arduino.app_bricks.dbstorage_tsstore` | Scalar values, trends, and AI estimates. |
| **Visual Evidence** | Local Filesystem | `/home/arduino/ArduinoApps/visiosense/evidence/` | JPEG images and metadata blobs. |
| **App Configuration** | Local Filesystem | `/home/arduino/ArduinoApps/visiosense/config.yaml` | Static settings and landmark definitions. |

---

## 2. Technical Specifications

### 2.1 Time-Series Metrics
All numerical data is handled by the `TimeSeriesStore` brick. This ensures that the Web UI can efficiently aggregate and chart data.

**Implementation Details:**
- **Import:** `from arduino.app_bricks.dbstorage_tsstore import TimeSeriesStore`
- **Writing Data:** 
  `db.write_sample(measure: str, value: float, timestamp: int)`
  - `measure`: The unique key for the metric.
  - `value`: The numerical value.
  - `timestamp`: Unix timestamp in milliseconds.
- **Reading Data:**
  `db.read_samples(measure: str, start_from: str, aggr_window: str, aggr_func: str, limit: int)`

### 2.2 Visual Evidence (Images)
Images are stored as files to avoid database bloat.

**Implementation Details:**
- **Root Path:** `/home/arduino/ArduinoApps/visiosense/evidence/`
- **Naming Convention:** `YYYYMMDD_HHMMSS.jpg`
- **Association:** To link a metric to an image, store the image filename as a string in a companion "pointer" metric or use the matching timestamp.

---

## 3. Flexible Schema Guide

To maintain flexibility while the data format is being finalized, follow these naming and structuring conventions:

### 3.1 Metric Prefixes
Use prefixes to categorize data keys:
- `env_`: Environmental sensors (e.g., `env_temp`, `env_humidity`).
- `vis_`: Visibility AI metrics (e.g., `vis_mor_estimate`, `vis_confidence`).
- `sys_`: System health (e.g., `sys_cpu_load`, `sys_uptime`).

### 3.2 Complex Data Handling
`TimeSeriesStore` only supports scalar floats. For complex AI output (e.g., a list of visible landmarks):
1. Store the primary estimate (e.g., `vis_mor_estimate`) in `TimeSeriesStore`.
2. Create a companion JSON file in the `evidence/` folder: `YYYYMMDD_HHMMSS_meta.json`.
3. Store the detailed breakdown in that JSON file.

---

## 4. Manual Data Maintenance

Automatic purging is disabled to prevent accidental data loss during demonstrations. Data should be cleared manually by the operator.

### 4.1 Clearing Visual Evidence
To delete all stored images:
```sh
rm -rf /home/arduino/ArduinoApps/visiosense/evidence/*
```

### 4.2 Clearing Time-Series Data
The `TimeSeriesStore` typically persists data to a local database file. To reset all metrics:
1. Stop the application.
2. Locate and delete the `TimeSeriesStore` database file (typically found in the app's data directory or `/home/arduino/.local/share/`).
3. Restart the application.

**Recommendation:** Clear data every 24–48 hours to maintain optimal system performance during the tech demo.

---

## 5. Data Flow Logic

### Ingestion Path
`Hardware Sensor/Camera` $\rightarrow$ `Arduino Sketch (C++)` $\rightarrow$ `Bridge.notify()` $\rightarrow$ `Python Callback` $\rightarrow$ `TimeSeriesStore / Filesystem`

### Consumption Path
`Web Dashboard` $\rightarrow$ `Python API Endpoint` $\rightarrow$ `TimeSeriesStore / Filesystem` $\rightarrow$ `JSON Response` $\rightarrow$ `UI Rendering`
