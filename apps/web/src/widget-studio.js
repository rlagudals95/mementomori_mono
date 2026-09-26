import './style.css';
import './widget.css';
import './widget-studio.css';
import { DEFAULT_YEARS, readState, lifeSnapshot, localDateKey, STORAGE_KEY } from './life.js';
import { WIDGET_KEY, WIDGET_SIZES, createWidget, updateWidget, readWidgetPreferences, openWidgetWindow, observeWidgetSize } from './widget.js';

const $ = id => document.getElementById(id);
let storage;
try { storage = window.localStorage; } catch { /* The preview works without persistence. */ }
let state = readState(storage);
let preferences = readWidgetPreferences(storage);
let floating;
let widgets = [];
let disconnectPreview;

function tick() {
  const snapshot = lifeSnapshot(state.profile || { birthday: '1995-01-01', years: DEFAULT_YEARS });
  const context = { demo: !state.profile, intention: state.intention?.date === localDateKey() ? state.intention.text : '' };
  widgets.forEach((widget, index) => updateWidget(widget, snapshot, index === 0 ? context : { ...context, intention: '' }));
  if (floating && !floating.popup.closed) updateWidget(floating.widget, snapshot, context);
}

function render() {
  const previous = $('widget-preview').querySelector('article');
  const previousSize = previous?.dataset.variant === preferences.variant ? previous.getBoundingClientRect() : null;
  disconnectPreview?.();
  const selected = createWidget(document, preferences);
  selected.dataset.variant = preferences.variant;
  if (previousSize) { selected.style.width = `${previousSize.width}px`; selected.style.height = `${previousSize.height}px`; }
  $('widget-preview').replaceChildren(selected);
  widgets = [selected];
  for (const variant of Object.keys(WIDGET_SIZES)) {
    const widget = createWidget(document, { variant, theme: preferences.theme });
    $(`specimen-${variant}`).replaceChildren(widget);
    widgets.push(widget);
  }
  document.querySelectorAll('[data-variant]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.variant === preferences.variant)));
  document.querySelectorAll('[data-theme]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.theme === preferences.theme)));
  const { width, height } = WIDGET_SIZES[preferences.variant];
  disconnectPreview = observeWidgetSize(selected, size => { $('preview-dimensions').textContent = `${Math.round(size.width)} × ${Math.round(size.height)} · 드래그로 크기 조절`; });
  $('preview-state').textContent = state.profile ? '나의 시간' : '1995.01.01생 예시';
  $('widget-context').textContent = state.profile ? `나의 설정 · ${state.profile.years}세 기준 · 오늘의 문장도 함께 표시됩니다.` : '예시를 보고 있어요. 메인 화면에서 생년월일을 설정하면 나의 시간이 표시됩니다.';
  tick();
}

function select(next) {
  const shapeChanged = next.variant !== undefined;
  if (shapeChanged) $('widget-preview').querySelector('article')?.removeAttribute('data-variant');
  preferences = { ...preferences, ...next };
  try { storage?.setItem(WIDGET_KEY, JSON.stringify(preferences)); }
  catch { $('studio-feedback').textContent = '선택은 이번 화면에서만 유지됩니다.'; }
  if (floating && !floating.popup.closed) {
    floating.widget.className = `mori-widget widget-${preferences.variant} widget-${preferences.theme}`;
    floating.popup.document.body.className = `widget-window widget-${preferences.theme}`;
    const size = WIDGET_SIZES[preferences.variant];
    if (shapeChanged) floating.popup.resizeTo(size.width + floating.popup.outerWidth - floating.popup.innerWidth, size.height + floating.popup.outerHeight - floating.popup.innerHeight);
  }
  render();
}
document.querySelectorAll('[data-variant]').forEach(button => button.addEventListener('click', () => select({ variant: button.dataset.variant })));
document.querySelectorAll('[data-theme]').forEach(button => button.addEventListener('click', () => select({ theme: button.dataset.theme })));
document.querySelectorAll('[data-select]').forEach(button => button.addEventListener('click', () => {
  select({ variant: button.dataset.select });
  document.querySelector('.widget-workbench').scrollIntoView({ behavior: 'instant', block: 'start' });
  document.querySelector(`[data-variant="${preferences.variant}"]`).focus({ preventScroll: true });
}));
$('studio-pip').addEventListener('click', async () => {
  try {
    if (floating && !floating.popup.closed) { floating.popup.focus(); return; }
    floating = await openWidgetWindow(document, preferences);
    floating.popup.addEventListener('pagehide', () => { floating = undefined; });
    tick();
  } catch { $('studio-feedback').textContent = '작은 창을 열지 못했어요. 데스크톱 Chrome에서 다시 시도해 주세요.'; }
});
if (!('documentPictureInPicture' in window)) {
  $('studio-pip').hidden = true;
  $('studio-feedback').textContent = '여기서 디자인을 비교할 수 있어요. 실제 작은 창은 지원되는 데스크톱 Chrome에서 열 수 있습니다.';
}
window.addEventListener('storage', event => {
  if (event.key === STORAGE_KEY || event.key === null) state = readState(storage);
  if (event.key === WIDGET_KEY || event.key === null) preferences = readWidgetPreferences(storage);
  render();
});
document.addEventListener('visibilitychange', () => { if (!document.hidden) tick(); });
render();
setInterval(() => { if (!document.hidden || floating) tick(); }, 1000);
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch(() => {}));
}
