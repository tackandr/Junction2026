# Arduino climate monitor data storage

This note describes how the `example_climate_monitor` app records sensor data and displays it in the web UI.

## Data flow

The Modulino temperature/humidity sensor is read by the Arduino sketch on the UNO Q's microcontroller about once per second. The sketch sends each reading to the Python app over the UNO Q Bridge. The Python app runs on the UNO Q's Linux side; it receives each Bridge notification in a callback rather than polling the sensor itself.

For each valid reading, the Python app adds a millisecond timestamp and writes temperature and relative humidity to `TimeSeriesStore`. It also calculates and stores dew point, heat index, and absolute humidity. If either sensor value is invalid, that sample is skipped.

```text
Modulino sensor
    -> MCU sketch (sample every second)
    -> Bridge notification
    -> Python callback on UNO Q Linux
    -> TimeSeriesStore / InfluxDB
    -> Web UI
```

## Database and persistence

Arduino's Time Series Brick stores these time-series values in InfluxDB. The Brick's Docker Compose configuration bind-mounts InfluxDB's data directory to `${APP_HOME:-.}/data/influx-data` ([Brick README](https://github.com/arduino/app-bricks-py/blob/main/src/arduino/app_bricks/dbstorage_tsstore/README.md), [compose configuration](https://github.com/arduino/app-bricks-py/blob/main/src/arduino/app_bricks/dbstorage_tsstore/brick_compose.yaml)). With the app's data directory retained on the UNO Q, the database data survives stopping and restarting the app, and a board reboot. Removing the app data directory also removes the database files.

The Brick currently sets a default retention period of **7 days** when `TimeSeriesStore` is initialized. The deployed Brick version controls the actual setting, so check that version if retaining data longer than a week matters ([current TimeSeriesStore source](https://github.com/arduino/app-bricks-py/blob/main/src/arduino/app_bricks/dbstorage_tsstore/__init__.py)).

This is a database, not a CSV file. The app's `GET /get_samples/{resource}/{start}/{aggr_window}` endpoint reads from it for chart display.

## How the web UI receives data

The live view is event-driven. When the Python callback stores a sample, it calls `WebUI.send_message`; the browser receives the message over the WebUI's WebSocket connection and updates the live chart. The browser does not poll the database for live readings ([WebUI Brick documentation](https://github.com/arduino/app-bricks-py/blob/main/src/arduino/app_bricks/web_ui/README.md)).

The 1-hour and 1-day views query stored history over HTTP when their tabs are selected:

- **1 hour:** mean values grouped into 5-minute windows.
- **1 day:** mean values grouped into 1-hour windows.

The chart API currently returns at most 100 results per request. Historical values come from the database; the live chart's current points are held in the browser and start fresh when the page is reloaded.

## Relevant app files

- `example_climate_monitor/sketch/sketch.ino` — reads the sensor every second and sends samples over Bridge.
- `example_climate_monitor/python/main.py` — stores samples, calculates derived metrics, pushes live updates, and serves historical queries.
- `example_climate_monitor/assets/app.js` — handles live messages and requests historical chart data.
