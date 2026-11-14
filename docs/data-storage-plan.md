# 📊 Data Storage Plan: VisioSense (Tech Demo Edition)

## 1. Goal
Provide a "zero-friction" storage setup for a tech demo. The priority is rapid deployment (pull repo $\rightarrow$ run) and extreme flexibility to change data formats on the fly.

**Core Principles:**
- **Edge-Only:** Everything lives on the Arduino UNO Q.
- **Minimal Setup:** Rely on pre-installed App Lab Bricks and standard Python.
- **Demo Focus:** Optimized for 12h-48h of data; no complex database migrations.

---

## 2. Data Strategy

The system manages four primary data streams:

### A. Telemetry (Temperature & Humidity) $\rightarrow$ `TimeSeriesStore`
Using the `arduino.app_bricks.dbstorage_tsstore` brick.
- **Approach:** Treat as a schema-less key-value store.
- **Keys:** `env_temp`, `env_humidity`.

### B. Processed Camera Data (AI Metrics) $\rightarrow$ Hybrid Storage
Results from the visibility pipeline.
- **Primary Metrics:** Scalar values (e.g., `vis_mor_estimate`) stored in `TimeSeriesStore`.
- **Detailed Metadata:** Complex results (e.g., landmark lists) stored as companion JSON files in the `/evidence/` folder.
- **Pattern:** Follow the logic found in `example_video_object_detection`.

### C. Camera Images (Visual Evidence) $\rightarrow$ Local Folder
Raw captures for verification.
- **Format:** Standard JPG.
- **Path:** `/home/arduino/ArduinoApps/visiosense/evidence/`

---

## 3. Lifecycle & Maintenance

To maximize reliability during a live demo and prevent flash memory exhaustion:

### 3.1 Manual Maintenance (Preferred)
Automatic purging is disabled to prevent accidental data loss. The operator will clear data manually:
- **Filesystem:** `rm -rf /home/arduino/ArduinoApps/visiosense/evidence/*`
- **Database:** Delete the `TimeSeriesStore` local db file and restart the app.

### 3.2 Suggested Maintenance Interval
- Clear data every **24–48 hours** to keep the system performant and the dashboard uncluttered.

---

## 4. Integration & Access

### Data Format Evolution
- **Flexible Naming:** Use descriptive prefixes (`env_`, `vis_`, `sys_`).
- **JSON Expansion:** New data types can be added by writing new keys to the store or adding new fields to the companion JSON files without updating a central schema.

### Web UI Connectivity
- **Host:** `http://commit-and-conquer.local:7000/`
- **Consumption:** 
    - Charts $\rightarrow$ Direct API calls to `TimeSeriesStore`.
    - Images $\rightarrow$ Static file serving from the `/evidence/` directory.
    
# About this document
It was created with Gemma 4 with human oversight. 
