import { exportSettingsFile, parseSettingsFile, storeSettingsFile } from './settings-transfer.js';
import './style.css';
import './widget.css';
import { readWidgetPreferences, openWidgetWindow, updateWidget, WIDGET_KEY } from './widget.js';
import { DEFAULT_YEARS, STORAGE_KEY, lifeSnapshot, validateProfile, readState, localDateKey } from './life.js';

const $ = (id) => document.getElementById(id);
const format = new Intl.NumberFormat('ko-KR');
const example = { birthday: '1995-01-01', years: DEFAULT_YEARS };
let storage;
try { storage = window.localStorage; } catch { /* In-memory fallback. */ }
let state = readState(storage);
let pipWindow;
let pipWidget;
let installPrompt;
let toastTimer;
let previousDay = localDateKey();
let calendarKey = '';
let lastSnapshot;
let focusReturn;

function notify(message) {
  $('toast').textContent = message;
  $('toast').hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { $('toast').hidden = true; }, 5000);
}

function persist() {
  try {
    if (!storage) throw new Error('Unavailable');
    storage.setItem(STORAGE_KEY, JSON.stringify(state));
    return true;
  } catch {
    notify('이 브라우저에 저장할 수 없어 이번 화면에서만 유지됩니다.');
    return false;
  }
}

function todayIntention() {
  return state.intention?.date === localDateKey() ? state.intention.text : '';
}

function openPanel(id) {
  if (id !== 'method-panel') {
    for (const other of ['settings-panel', 'keep-panel']) {
      $(other).hidden = other !== id;
      $(other === 'settings-panel' ? 'settings-toggle' : 'keep-toggle').setAttribute('aria-expanded', String(other === id));
    }
  } else $(id).hidden = false;
  $(id).scrollIntoView({ behavior: 'instant', block: 'start' });
  $(id).querySelector('input, button')?.focus({ preventScroll: true });
}

function closePanel(id) {
  $(id).hidden = true;
  const button = $(id === 'settings-panel' ? 'settings-toggle' : id === 'keep-panel' ? 'keep-toggle' : 'method-link');
  button.setAttribute('aria-expanded', 'false');
  button.focus({ preventScroll: true });
}

function setupPanels() {
  for (const [trigger, panel] of [['settings-toggle', 'settings-panel'], ['keep-toggle', 'keep-panel'], ['method-link', 'method-panel']]) {
    $(trigger).addEventListener('click', () => $(panel).hidden ? openPanel(panel) : closePanel(panel));
  }
  document.querySelectorAll('[data-close]').forEach((button) => button.addEventListener('click', () => closePanel(button.dataset.close)));
  $('start-button').addEventListener('click', () => { openPanel('settings-panel'); $('birthday').focus(); });
}

function buildDial() {
  const ns = 'http://www.w3.org/2000/svg';
  for (let i = 0; i < 100; i++) {
    const angle = i / 100 * 2 * Math.PI - Math.PI / 2;
    const tick = document.createElementNS(ns, 'line');
    const inside = i % 5 === 0 ? 65 : 70;
    tick.setAttribute('x1', String(90 + Math.cos(angle) * inside));
    tick.setAttribute('y1', String(90 + Math.sin(angle) * inside));
    tick.setAttribute('x2', String(90 + Math.cos(angle) * 77));
    tick.setAttribute('y2', String(90 + Math.sin(angle) * 77));
    tick.setAttribute('stroke-width', '1');
    $('dial-ticks').append(tick);
  }
}

function drawCalendar(snapshot) {
  const canvas = $('weeks-canvas');
  const width = canvas.getBoundingClientRect().width;
  if (!width) return;
  const columns = width < 440 ? 52 : 104;
  const rows = Math.ceil(snapshot.totalWeeks / columns);
  const pitch = width / columns;
  const height = rows * pitch;
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvas.style.height = `${height}px`;
  canvas.width = Math.round(width * dpr);
  canvas.height = Math.round(height * dpr);
  const context = canvas.getContext('2d');
  if (!context) return;
  context.scale(dpr, dpr);
  for (let i = 0; i < snapshot.totalWeeks; i++) {
    const current = i === snapshot.livedWeeks && !snapshot.passed;
    context.fillStyle = current ? '#fafafa' : i < snapshot.livedWeeks ? '#333333' : '#dedede';
    context.beginPath();
    context.arc((i % columns + .5) * pitch, (Math.floor(i / columns) + .5) * pitch, pitch * (current ? .38 : .255), 0, Math.PI * 2);
    context.fill();
    if (current) {
      context.strokeStyle = '#111111';
      context.lineWidth = Math.max(1, pitch * .17);
      context.stroke();
    }
  }
  const future = Math.max(0, snapshot.totalWeeks - snapshot.livedWeeks - (snapshot.passed ? 0 : 1));
  canvas.setAttribute('aria-label', `한 점이 한 주입니다. 총 ${snapshot.totalWeeks}주 중 ${snapshot.livedWeeks}주를 지났고, 이번 주 이후 ${future}주가 있습니다.`);
  $('lived-weeks').textContent = format.format(snapshot.livedWeeks);
  $('future-weeks').textContent = format.format(future);
}

function updatePip(snapshot) {
  if (!pipWindow || pipWindow.closed) return;
  updateWidget(pipWidget, snapshot, { demo: !state.profile, intention: todayIntention() });
}

function tick(force = false) {
  const profile = state.profile || example;
  // Device clock can change. Retain the entered birthday and wait until it is valid again.
  if (validateProfile(profile)) return;
  const snapshot = lifeSnapshot(profile);
  lastSnapshot = snapshot;
  const isDays = state.mode === 'days';
  $('remaining-number').textContent = format.format(isDays ? snapshot.days : snapshot.seconds);
  $('remaining-unit').textContent = isDays ? '일' : '초';
  $('time-detail').textContent = `${format.format(snapshot.days)}일 ${String(snapshot.hours).padStart(2, '0')}시간 ${String(snapshot.minutes).padStart(2, '0')}분 ${String(snapshot.second).padStart(2, '0')}초`;
  $('time-detail').hidden = isDays || snapshot.passed;
  $('countdown-label').textContent = snapshot.passed ? '설정한 기준에 도착했어요' : '기준 수명까지 남은 시간';
  $('passed-message').hidden = !snapshot.passed;
  const percent = snapshot.progress * 100;
  $('life-percent').textContent = `${percent.toFixed(1)}%`;
  $('life-line-fill').style.transform = `scaleX(${snapshot.progress})`;
  $('life-line-now').style.left = `${percent}%`;
  $('birth-label').textContent = `${profile.birthday.replaceAll('-', '.')} 시작`;
  $('reference-label').textContent = `${profile.years}세의 기준`;
  const angle = snapshot.progress * Math.PI * 2 - Math.PI / 2;
  $('dial-now').setAttribute('cx', String(90 + Math.cos(angle) * 77));
  $('dial-now').setAttribute('cy', String(90 + Math.sin(angle) * 77));
  const key = `${profile.birthday}/${profile.years}/${snapshot.livedWeeks}`;
  if (key !== calendarKey || force) {
    calendarKey = key;
    [...$('dial-ticks').children].forEach((tick, index) => tick.setAttribute('stroke', index < percent ? '#333333' : '#dedede'));
    drawCalendar(snapshot);
  }
  const day = localDateKey();
  if (day !== previousDay) {
    previousDay = day;
    $('intention-input').value = todayIntention();
    $('intention-save').textContent = '기억하기 ↗';
    $('birthday').max = day;
  }
  updatePip(snapshot);
}

function updateStateUI() {
  $('demo-notice').hidden = Boolean(state.profile);
  $('reset-button').hidden = !state.profile && !state.intention;
  $('birthday').value = state.profile?.birthday || '';
  $('birthday').max = localDateKey();
  $('years').value = state.profile?.years || DEFAULT_YEARS;
  $('intention-input').value = todayIntention();
  $('intention-save').textContent = todayIntention() ? '문장 바꾸기 ↗' : '기억하기 ↗';
  $('seconds-mode').setAttribute('aria-pressed', String(state.mode !== 'days'));
  $('days-mode').setAttribute('aria-pressed', String(state.mode === 'days'));
  tick(true);
}

$('profile-form').addEventListener('submit', (event) => {
  event.preventDefault();
  const profile = { birthday: $('birthday').value, years: Number($('years').value) };
  const error = validateProfile(profile);
  $('profile-error').textContent = error;
  if (error) {
    (error.includes('수명') ? $('years') : $('birthday')).focus();
    return;
  }
  state.profile = profile;
  const saved = persist();
  updateStateUI();
  closePanel('settings-panel');
  if (saved) notify('당신의 시간을 이 기기에 기억해 두었어요.');
});

$('intention-form').addEventListener('submit', (event) => {
  event.preventDefault();
  const text = $('intention-input').value.trim().slice(0, 100);
  state.intention = text ? { text, date: localDateKey() } : undefined;
  const saved = persist();
  $('intention-save').textContent = text ? '문장 바꾸기 ↗' : '기억하기 ↗';
  $('reset-button').hidden = !state.profile && !state.intention;
  tick();
  if (saved) notify(text ? '오늘의 한 문장을 기억해 두었어요.' : '오늘의 문장을 지웠어요.');
});

for (const mode of ['seconds', 'days']) {
  $(`${mode}-mode`).addEventListener('click', () => {
    state.mode = mode;
    persist();
    $('seconds-mode').setAttribute('aria-pressed', String(mode === 'seconds'));
    $('days-mode').setAttribute('aria-pressed', String(mode === 'days'));
    tick();
  });
}

$('reset-button').addEventListener('click', () => { $('reset-confirmation').hidden = false; $('cancel-reset').focus(); });
$('cancel-reset').addEventListener('click', () => { $('reset-confirmation').hidden = true; $('reset-button').focus(); });
$('confirm-reset').addEventListener('click', () => {
  try {
    if (storage) storage.removeItem(STORAGE_KEY);
  } catch { notify('저장된 기록을 지우지 못했어요. 브라우저의 사이트 데이터 설정을 확인해 주세요.'); return; }
  state = {};
  $('profile-error').textContent = '';
  $('reset-confirmation').hidden = true;
  updateStateUI();
  closePanel('settings-panel');
  notify('이 기기에 저장한 기록을 지웠어요.');
});

function exitFocus() {
  document.body.classList.remove('focus-mode');
  $('intention-input').readOnly = false;
  $('exit-focus').hidden = true;
  focusReturn?.focus();
  tick(true);
}
$('focus-button').addEventListener('click', () => {
  focusReturn = $('focus-button');
  document.body.classList.add('focus-mode');
  $('intention-input').readOnly = true;
  $('exit-focus').hidden = false;
  window.scrollTo(0, 0);
  $('exit-focus').focus();
});
$('exit-focus').addEventListener('click', exitFocus);
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && document.body.classList.contains('focus-mode')) exitFocus();
  else if (event.key === 'Escape') for (const id of ['settings-panel', 'keep-panel', 'method-panel']) if (!$(id).hidden) closePanel(id);
});

if (!('documentPictureInPicture' in window)) {
  $('pip-button').hidden = true;
  $('pip-description').textContent = '이 브라우저는 작은 상시 표시 창을 지원하지 않아요. 데스크톱 Chrome에서 열거나 아래 집중 화면을 이용해 주세요.';
}
$('pip-button').addEventListener('click', async () => {
  try {
    if (pipWindow && !pipWindow.closed) { pipWindow.focus(); return; }
    const floating = await openWidgetWindow(document, readWidgetPreferences(storage));
    pipWindow = floating.popup;
    pipWidget = floating.widget;
    pipWindow.addEventListener('pagehide', () => { pipWindow = undefined; pipWidget = undefined; });
    tick();
  } catch { notify('작은 창을 열지 못했어요. 데스크톱 Chrome에서 다시 시도해 주세요.'); }
});

window.addEventListener('beforeinstallprompt', (event) => {
  event.preventDefault();
  installPrompt = event;
  $('install-button').hidden = false;
});
$('install-button').addEventListener('click', async () => {
  if (!installPrompt) return;
  try { await installPrompt.prompt(); await installPrompt.userChoice; }
  catch { notify('브라우저 메뉴에서 앱 설치를 선택해 주세요.'); }
  installPrompt = undefined;
  $('install-button').hidden = true;
});
window.addEventListener('appinstalled', () => { $('install-button').hidden = true; notify('메멘토모리를 곁에 두었어요.'); });

window.addEventListener('storage', (event) => {
  if (event.key === STORAGE_KEY || event.key === null) { state = readState(storage); updateStateUI(); }
});
document.addEventListener('visibilitychange', () => { if (!document.hidden) tick(true); });
window.addEventListener('pageshow', () => tick(true));
new ResizeObserver(() => { if (lastSnapshot) drawCalendar(lastSnapshot); }).observe($('weeks-canvas'));

setupPanels();
buildDial();
updateStateUI();
setInterval(() => { if (!document.hidden || pipWindow) tick(); }, 1000);
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => { navigator.serviceWorker.register('/sw.js').catch(() => notify('오프라인 준비를 마치지 못했어요. 연결 상태에서 다시 열어 주세요.')); });
}

// The same versioned file is read by the native Mac app. Nothing is sent to a server.
let pendingImport;
$('export-settings').addEventListener('click', () => {
  try {
    const text = exportSettingsFile(state, readWidgetPreferences(storage));
    const url = URL.createObjectURL(new Blob([text], { type: 'application/json' }));
    const link = document.createElement('a');
    link.href = url; link.download = 'mementomori-settings.json'; link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    $('transfer-message').textContent = '설정 파일을 내보냈어요. Mac 앱의 설정에서 가져오세요.';
  } catch (error) { $('transfer-message').textContent = error.message; }
});
$('import-settings').addEventListener('click', () => $('settings-file').click());
$('settings-file').addEventListener('change', async (event) => {
  const file = event.target.files[0];
  event.target.value = '';
  pendingImport = undefined; $('import-confirmation').hidden = true;
  if (!file) return;
  try {
    if (file.size > 65536) throw new Error('설정 파일은 64KB 이하여야 합니다.');
    pendingImport = parseSettingsFile(await file.text());
    $('transfer-message').textContent = '';
    $('import-confirmation').hidden = false;
    $('cancel-import').focus();
  } catch (error) { $('transfer-message').textContent = error.message; }
});
$('cancel-import').addEventListener('click', () => {
  pendingImport = undefined; $('import-confirmation').hidden = true; $('import-settings').focus();
});
$('confirm-import').addEventListener('click', () => {
  if (!pendingImport) return;
  try {
    storeSettingsFile(storage, pendingImport, STORAGE_KEY, WIDGET_KEY);
    state = pendingImport.state;
    if (pipWindow && !pipWindow.closed) pipWindow.close();
    updateStateUI();
    $('profile-error').textContent = '';
    $('transfer-message').textContent = '설정을 가져왔어요. 같은 시간 기준으로 시작합니다.';
    pendingImport = undefined; $('import-confirmation').hidden = true;
    $('import-settings').focus();
  } catch (error) { $('transfer-message').textContent = error.message; }
});
