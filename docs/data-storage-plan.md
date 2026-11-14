# 📊 Data Storage Plan: VisioSense (Tech Demo Edition)

## 1. Goal
Provide a "zero-friction" storage setup for a tech demo. The priority is rapid deployment (pull repo $\rightarrow$ run) and flexibility to change data formats on the fly.

**Constraints:**
- **Retention:** 12h to 48h only.
- **Setup:** Minimal; rely on pre-installed App Lab Bricks and standard Python.
- **Flexibility:** Handle undetermined data formats.

---

## 2. Simplified Data Strategy

### A. Metrics & Telemetry $\rightarrow$ `TimeSeriesStore`
We will continue using the `TimeSeriesStore` brick because it is pre-installed and handles the time-stamping and basic storage automatically.
- **Flexibility:** We will treat it as a key-value store. If we discover a new metric (e.g., `fog_density`), we simply start writing to a new key without updating a schema.
- **Simplicity:** No database configuration required.

### B. Visual Evidence $\rightarrow$ Local Folder
Images will be saved to a local directory.
- **Format:** Standard JPG.
- **Path:** `/home/arduino/ArduinoApps/visiosense/evidence/`

---

## 3. Lean Lifecycle Management (The "Demo Reset")

Since we only need 12-48h of data, we will avoid complex pruning. Instead, we implement a **Simple Purge**:

1.  **Startup Wipe (Optional):** The app can be configured to clear the `evidence/` folder on every fresh reboot to ensure the demo starts clean.
2.  **Time-based TTL:** A simple background thread in `main.py` that deletes files older than 48 hours once every hour.
    - *Logic:* `if file.age > 48h: os.remove(file)`
3.  **Capped Storage:** A hard limit on the number of images (e.g., max 500 images). When the limit is hit, the oldest is deleted.

---

## 4. Integration & Flexibility

### Data Format Evolution
To keep the system flexible while we determine the actual format:
- **Metric naming:** Use descriptive keys (e.g., `vis_mor_estimate` instead of `v1`).
- **JSON Blobs:** If a metric becomes too complex for a single float (e.g., a list of detected landmarks), we will store a JSON string in a separate log file and link it via timestamp to the `TimeSeriesStore`.

### Web UI Access
- **Direct API:** The Web UI will query the `TimeSeriesStore` directly for charts.
- **Static Serving:** Images will be served as static files from the `evidence/` directory.
