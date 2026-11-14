# ADR-0002: Data Storage Architecture

- **Status:** Accepted
- **Date:** 2026-11-14
- **Decision makers:** Project Team
- **Technical area:** Data Persistence & Storage
- **Related issues:** N/A
- **Supersedes:** N/A
- **Superseded by:** N/A

## Context and Problem Statement

The VisioSense application needs to store four distinct types of data: temperature, humidity, raw camera images, and AI-processed visibility metrics. The system runs on an Arduino UNO Q (Edge device) with finite flash storage and needs to be easily deployable for a tech demo. We need a storage strategy that is flexible enough to handle evolving AI data formats but simple enough to require zero manual database configuration.

## Decision Drivers

- **Zero-Friction Setup:** The app should be "pull and run" without external DB installations.
- **Edge Constraints:** Minimize flash memory wear and avoid filling the disk during the demo.
- **Flexibility:** The AI output format for visibility estimation is not yet finalized.
- **Human Verifiability:** Must be able to link a numerical visibility estimate to the actual image that produced it.

## Considered Options

1. **Full Database Approach (SQLite/InfluxDB):** Use a structured database for all metrics and file paths for images.
2. **Flat File Approach (CSV/JSON):** Store everything in text files.
3. **Hybrid App-Brick Approach (TimeSeriesStore + Filesystem):** Use the pre-installed `TimeSeriesStore` for scalars and the local filesystem for images/metadata.

## Decision Outcome

**Chosen option:** Hybrid App-Brick Approach

**Rationale:** The `TimeSeriesStore` brick is already integrated into the Arduino App Lab environment, providing an immediate, optimized way to handle time-series data without configuration. Combining this with a simple local folder for images satisfies both the performance needs of the dashboard and the flexibility required for AI evidence.

### Positive Consequences

- **Rapid Deployment:** No database setup is required on the board.
- **Performance:** `TimeSeriesStore` is optimized for the types of queries the Web UI needs.
- **Transparency:** Raw images are easily accessible on the filesystem for debugging.

### Negative Consequences and Trade-offs

- **Limited Data Types:** `TimeSeriesStore` only supports scalar floats; complex AI results must be offloaded to separate JSON files.
- **Manual Cleanup:** To avoid complex automation bugs during a demo, we accept the trade-off of requiring manual data purging.

## Options Analysis

| Option | Benefits | Drawbacks | Notes |
| --- | --- | --- | --- |
| SQLite | Structured, powerful queries | Requires schema management | Overkill for a 48h demo |
| Flat Files | Human readable, simple | Slow for large time-series | Poor performance for charts |
| Hybrid | Zero-setup, optimized trends | Split storage (DB vs Files) | Best fit for App Lab ecosystem |

## Implementation Notes

- [x] Create `docs/data-storage-plan.md`
- [x] Create `data-storage/data-storage-description.md`
- [ ] Implement `TimeSeriesStore` integration in `main.py`
- [ ] Setup `/evidence/` directory logic for image storage

## Validation and Review

- **Success criteria:** Dashboard correctly renders temperature and visibility trends from `TimeSeriesStore` and displays corresponding images from the filesystem.
- **Review date or trigger:** After the first end-to-end integration test of the visibility pipeline.

## References

- [Data Storage Plan](docs/data-storage-plan.md)
- [Data Storage Description](data-storage/data-storage-description.md)

## Change History

| Date | Change | Author |
| --- | --- | --- |
| 2026-11-14 | Initial proposal and acceptance | AI Agent |
