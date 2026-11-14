const captureButton = document.querySelector('#captureButton');
const buttonLabel = document.querySelector('#buttonLabel');
const statusMessage = document.querySelector('#statusMessage');
const emptyState = document.querySelector('#emptyState');
const resultImage = document.querySelector('#resultImage');
const resultCount = document.querySelector('#resultCount');
const resultSummary = document.querySelector('#resultSummary');
const detectionList = document.querySelector('#detectionList');
const frameState = document.querySelector('#frameState');

captureButton.addEventListener('click', captureAndDetect);

async function captureAndDetect() {
  setBusy(true);
  statusMessage.textContent = 'Capturing a fresh frame and running detection…';

  try {
    const response = await fetch('/capture', { method: 'POST' });
    const result = await response.json();

    if (!response.ok || !result.success) {
      throw new Error(result.error || `Capture failed (${response.status})`);
    }

    emptyState.hidden = true;
    resultImage.src = `data:image/jpeg;base64,${result.image}`;
    resultImage.hidden = false;
    frameState.textContent = 'Frame captured';
    resultCount.textContent = String(result.count);
    resultSummary.textContent = result.count === 1
      ? '1 object identified in this frame.'
      : `${result.count} objects identified in this frame.`;
    renderDetections(result.detections);
    statusMessage.textContent = 'Detection complete.';
  } catch (error) {
    statusMessage.textContent = error.message || 'Unable to capture an image.';
  } finally {
    setBusy(false);
  }
}

function renderDetections(detections) {
  detectionList.replaceChildren();

  if (!detections.length) {
    resultSummary.textContent = 'No objects were detected in this frame.';
    return;
  }

  detections.forEach((detection, index) => {
    const item = document.createElement('li');
    item.className = 'detection-item';

    const marker = document.createElement('span');
    marker.className = 'detection-marker';
    marker.textContent = String(index + 1).padStart(2, '0');

    const label = document.createElement('span');
    label.className = 'detection-label';
    label.textContent = detection.label;

    item.append(marker, label);
    detectionList.append(item);
  });
}

function setBusy(isBusy) {
  captureButton.disabled = isBusy;
  buttonLabel.textContent = isBusy ? 'Processing frame…' : 'Capture & detect';
  captureButton.classList.toggle('is-busy', isBusy);
}
