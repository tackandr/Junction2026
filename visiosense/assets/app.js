// SPDX-FileCopyrightText: Copyright (C) Arduino s.r.l. and/or its affiliated companies
//
// SPDX-License-Identifier: MPL-2.0

const ui = new WebUI();
const image = document.getElementById('latest-image');
const placeholder = document.getElementById('placeholder');
const status = document.getElementById('status');
const imageSize = document.getElementById('image-size');
const connectionError = document.getElementById('connection-error');

ui.on_connect(() => {
  connectionError.hidden = true;
  status.textContent = 'Connected · waiting for camera';
});

ui.on_disconnect(() => {
  connectionError.textContent = 'Connection to the UNO Q was lost.';
  connectionError.hidden = false;
  status.textContent = 'Disconnected';
  status.classList.remove('ready');
});

ui.on_message('snapshot', showSnapshot);
ui.on_message('camera_error', message => {
  status.textContent = `Camera error: ${message.message}`;
  status.classList.remove('ready');
});

function showSnapshot(snapshot) {
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
