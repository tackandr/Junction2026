// SPDX-FileCopyrightText: Copyright (C) Arduino s.r.l. and/or its affiliated companies
//
// SPDX-License-Identifier: MPL-2.0

const ui = new WebUI();
const image = document.getElementById('latest-image');
const placeholder = document.getElementById('placeholder');
const status = document.getElementById('status');
const imageSize = document.getElementById('image-size');
const connectionError = document.getElementById('connection-error');
const detectionList = document.getElementById('detection-list');
const detectionCount = document.getElementById('detection-count');
const currentVisibility = document.getElementById('current-visibility');
const visibilityCanvas = document.getElementById('visibility-chart');
const visibilityChartEmpty = document.getElementById('visibility-chart-empty');
const climateSeries = {
  temperature: {
    canvas: document.getElementById('temperature-chart'),
    empty: document.getElementById('temperature-chart-empty'),
    samples: new Map(),
    unit: '°C',
    color: '#f2aa61',
  },
  humidity: {
    canvas: document.getElementById('humidity-chart'),
    empty: document.getElementById('humidity-chart-empty'),
    samples: new Map(),
    unit: '%',
    color: '#61c9d6',
    min: 0,
    max: 100,
  },
};
let displayedCapture = null;
const visibilitySamples = new Map();

const visibilityChart = new Chart(visibilityCanvas.getContext('2d'), {
  type: 'line',
  data: {
    labels: [],
    datasets: [
      {
        label: 'Visibility distance',
        data: [],
        borderColor: '#77d9bb',
        backgroundColor: 'rgba(119, 217, 187, 0.12)',
        fill: true,
        stepped: 'after',
        pointRadius: 1.5,
        borderWidth: 2,
      },
    ],
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    animation: false,
    scales: {
      y: {
        min: 0,
        max: 1000,
        ticks: {
          stepSize: 250,
          callback: value => `${value} m`,
        },
        grid: { color: 'rgba(174, 189, 184, 0.12)' },
      },
      x: {
        grid: { display: false },
        ticks: { maxTicksLimit: 8, maxRotation: 0 },
      },
    },
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          label: context => ` ${Number(context.parsed.y).toFixed(0)} m`,
        },
      },
    },
  },
});

for (const series of Object.values(climateSeries)) {
  series.chart = createClimateChart(series);
}

ui.on_connect(() => {
  connectionError.hidden = true;
  status.textContent = 'Connected · waiting for camera';
  loadVisibilityHistory();
  loadClimateHistory();
});

ui.on_disconnect(() => {
  connectionError.textContent = 'Connection to the UNO Q was lost.';
  connectionError.hidden = false;
  status.textContent = 'Disconnected';
  status.classList.remove('ready');
});

ui.on_message('snapshot', showSnapshot);
ui.on_message('detection_result', showDetections);
ui.on_message('detection_error', showDetectionError);
ui.on_message('visibility', addVisibilitySample);
ui.on_message('temperature', sample => addClimateSample('temperature', sample));
ui.on_message('humidity', sample => addClimateSample('humidity', sample));
ui.on_message('camera_error', message => {
  status.textContent = `Camera error: ${message.message}`;
  status.classList.remove('ready');
});

function showSnapshot(snapshot) {
  displayedCapture = snapshot.captured_at;
  detectionCount.textContent = 'Analyzing';
  detectionList.replaceChildren(makeMessage('Analyzing the latest image…'));

  const cacheKey = encodeURIComponent(snapshot.captured_at);
  image.onload = () => {
    image.hidden = false;
    placeholder.hidden = true;
    status.textContent = `Latest image · ${new Date(snapshot.captured_at).toLocaleTimeString()}`;
    status.classList.add('ready');
    imageSize.textContent = `${snapshot.width} × ${snapshot.height}`;
    connectionError.hidden = true;
  };
  image.onerror = () => {
    status.textContent = 'Could not load the latest JPEG image';
    status.classList.remove('ready');
  };
  image.src = `/latest.jpg?t=${cacheKey}`;
}

function showDetections(message) {
  if (message.captured_at !== displayedCapture) return;

  const detections = Array.isArray(message.detections) ? message.detections : [];
  detectionCount.textContent = `${detections.length} ${detections.length === 1 ? 'object' : 'objects'}`;
  detectionList.replaceChildren();

  if (detections.length === 0) {
    detectionList.append(makeMessage('No objects detected in this image.'));
    return;
  }

  for (const detection of detections) {
    const row = document.createElement('li');
    row.className = 'detection-row';

    const label = document.createElement('strong');
    label.className = 'detection-label';
    label.textContent = detection.class_name;

    const confidence = document.createElement('span');
    confidence.className = 'detection-confidence';
    confidence.textContent = `${Number(detection.confidence).toFixed(1)}%`;

    const box = document.createElement('code');
    box.className = 'detection-box';
    const coordinates = Array.isArray(detection.bounding_box_xyxy)
      ? detection.bounding_box_xyxy.join(', ')
      : 'unavailable';
    box.textContent = `box [${coordinates}] px`;

    row.append(label, confidence, box);
    detectionList.append(row);
  }
}

function showDetectionError(message) {
  if (message.captured_at !== displayedCapture) return;
  detectionCount.textContent = 'Error';
  detectionList.replaceChildren(makeMessage(`Object detection failed: ${message.message}`));
}

function makeMessage(text) {
  const item = document.createElement('li');
  item.className = 'empty-result';
  item.textContent = text;
  return item;
}

async function loadVisibilityHistory() {
  try {
    const response = await fetch('/get_samples/visibility_in_air/-1h/1m');
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const samples = await response.json();
    for (const sample of samples) addVisibilitySample(sample, false);
    renderVisibilityChart();
  } catch (error) {
    console.warn('Could not load visibility history:', error);
  }
}

async function loadClimateHistory() {
  await Promise.all([
    loadClimateSeriesHistory('temperature'),
    loadClimateSeriesHistory('humidity'),
  ]);
}

async function loadClimateSeriesHistory(measurement) {
  try {
    const response = await fetch(`/get_samples/${measurement}/-1h/1m`);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const samples = await response.json();
    for (const sample of samples) addClimateSample(measurement, sample, false);
    renderClimateChart(climateSeries[measurement]);
  } catch (error) {
    console.warn(`Could not load ${measurement} history:`, error);
  }
}

function addClimateSample(measurement, sample, render = true) {
  const series = climateSeries[measurement];
  const timestamp = Number(sample.ts);
  const value = Number(sample.value);
  if (!series || !Number.isFinite(timestamp) || !Number.isFinite(value)) return;

  series.samples.set(timestamp, value);
  const timestamps = [...series.samples.keys()].sort((a, b) => a - b);
  while (timestamps.length > 120) {
    series.samples.delete(timestamps.shift());
  }

  if (render) renderClimateChart(series);
}

function renderClimateChart(series) {
  const samples = [...series.samples.entries()].sort(([a], [b]) => a - b);
  series.chart.data.labels = samples.map(([timestamp]) =>
    new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
  );
  series.chart.data.datasets[0].data = samples.map(([, value]) => value);
  series.empty.hidden = samples.length > 0;
  series.chart.update('none');
}

function createClimateChart(series) {
  return new Chart(series.canvas.getContext('2d'), {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: series.unit,
          data: [],
          borderColor: series.color,
          backgroundColor: `${series.color}20`,
          fill: true,
          pointRadius: 1,
          borderWidth: 2,
          tension: 0.2,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: false,
      scales: {
        y: {
          min: series.min,
          max: series.max,
          ticks: { callback: value => `${value} ${series.unit}` },
          grid: { color: 'rgba(174, 189, 184, 0.12)' },
        },
        x: {
          grid: { display: false },
          ticks: { maxTicksLimit: 7, maxRotation: 0 },
        },
      },
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: context => ` ${Number(context.parsed.y).toFixed(1)} ${series.unit}`,
          },
        },
      },
    },
  });
}

function addVisibilitySample(sample, render = true) {
  const timestamp = Number(sample.ts);
  const value = Number(sample.value);
  if (!Number.isFinite(timestamp) || !Number.isFinite(value)) return;

  visibilitySamples.set(timestamp, value);
  currentVisibility.textContent = `${value.toFixed(0)} m`;

  const sortedTimestamps = [...visibilitySamples.keys()].sort((a, b) => a - b);
  while (sortedTimestamps.length > 120) {
    visibilitySamples.delete(sortedTimestamps.shift());
  }

  if (render) renderVisibilityChart();
}

function renderVisibilityChart() {
  const samples = [...visibilitySamples.entries()].sort(([a], [b]) => a - b);
  if (samples.length > 0) {
    currentVisibility.textContent = `${samples[samples.length - 1][1].toFixed(0)} m`;
  }
  visibilityChart.data.labels = samples.map(([timestamp]) =>
    new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
  );
  visibilityChart.data.datasets[0].data = samples.map(([, value]) => value);
  visibilityChartEmpty.hidden = samples.length > 0;
  visibilityChart.update('none');
}
