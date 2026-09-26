export const WIDGET_KEY = 'mementomori.widget.v1';
export const WIDGET_SIZES = {
  wide: { width: 360, height: 190, label: '가로형' },
  square: { width: 190, height: 190, label: '정사각형' },
  slim: { width: 360, height: 84, label: '한 줄형' },
};
const number = new Intl.NumberFormat('ko-KR');

export function readWidgetPreferences(storage) {
  try {
    const value = JSON.parse(storage.getItem(WIDGET_KEY));
    return {
      variant: Object.hasOwn(WIDGET_SIZES, value?.variant) ? value.variant : 'wide',
      theme: value?.theme === 'light' ? 'light' : 'dark',
    };
  } catch { return { variant: 'wide', theme: 'dark' }; }
}

// Shared by the design preview and the actual floating window.
export function createWidget(doc, { variant = 'wide', theme = 'dark', onClose } = {}) {
  const root = doc.createElement('article');
  root.className = `mori-widget widget-${variant} widget-${theme}`;
  root.setAttribute('aria-label', `메멘토모리 ${WIDGET_SIZES[variant].label} 위젯`);
  root.innerHTML = `
    <div class="widget-top"><span class="widget-wordmark">mementomori.</span><span class="widget-live" aria-hidden="true"></span></div>
    <div class="widget-time">
      <span class="widget-caption" data-caption>당신의 시간은 유한합니다.</span>
      <div class="widget-number" role="timer" aria-live="off"><span data-value>—</span><span class="widget-unit" data-unit>초</span></div>
    </div>
    <div class="widget-horizon" aria-hidden="true"><span class="widget-elapsed"></span><i class="widget-now"></i><i class="widget-end"></i></div>
    <div class="widget-bottom"><span data-thought>이 1초는 돌아오지 않습니다.</span><span class="widget-fraction" data-fraction></span></div>
    <span class="widget-accessible" data-description></span>`;
  if (onClose) {
    const close = doc.createElement('button');
    close.className = 'widget-close';
    close.setAttribute('aria-label', '작은 창 닫기');
    close.textContent = '×';
    close.addEventListener('click', onClose);
    root.append(close);
  }
  return root;
}

export function updateWidget(root, snapshot, { demo = false, intention = '' } = {}) {
  const square = root.classList.contains('widget-square');
  root.querySelector('[data-value]').textContent = number.format(square ? snapshot.days : snapshot.seconds);
  root.querySelector('[data-unit]').textContent = square ? '일' : '초';
  const years = number.format(snapshot.referenceYears);
  root.querySelector('[data-caption]').textContent = `${demo ? '예시 · ' : ''}${snapshot.passed ? '오늘도, 당신의 시간입니다.' : '당신의 시간은 유한합니다.'}`;
  root.querySelector('.widget-number').title = `${years}세까지 남은 시간 · 설정한 나이를 기준으로 계산하며 개인의 수명 예측이 아닙니다.`;
  root.querySelector('[data-fraction]').textContent = `지나온 ${(snapshot.progress * 100).toFixed(1)}%`;
  const thought = snapshot.passed ? '오늘도 삶은 계속됩니다.' : intention || (square ? '오늘은 다시 오지 않습니다.' : '이 1초는 돌아오지 않습니다.');
  root.querySelector('[data-thought]').textContent = thought;
  root.querySelector('[data-thought]').title = thought;
  root.querySelector('[data-description]').textContent = `${years}세까지의 시간 중 ${(snapshot.progress * 100).toFixed(1)}%가 지났습니다. 설정한 나이를 기준으로 계산한 값이며 개인의 수명 예측이 아닙니다.`;
  root.style.setProperty('--life-progress', String(snapshot.progress));
}

export async function openWidgetWindow(sourceDocument, preferences) {
  const { width, height } = WIDGET_SIZES[preferences.variant];
  const popup = await window.documentPictureInPicture.requestWindow({ width, height });
  const doc = popup.document;
  doc.documentElement.lang = 'ko';
  doc.title = '메멘토모리';
  sourceDocument.querySelectorAll('style, link[rel="stylesheet"]').forEach(style => doc.head.append(style.cloneNode(true)));
  doc.body.className = `widget-window widget-${preferences.theme}`;
  const widget = createWidget(doc, { ...preferences, onClose: () => popup.close() });
  widget.querySelector('[data-value]').id = 'pip-value';
  widget.querySelector('[data-caption]').id = 'pip-caption';
  doc.body.append(widget);
  const disconnect = observeWidgetSize(widget);
  popup.addEventListener('pagehide', disconnect, { once: true });
  return { popup, widget };
}

// One layout responds to its actual bounds in both the preview and the PiP window.
export function observeWidgetSize(widget, onResize = () => {}) {
  widget.dataset.responsive = '';
  const update = () => {
    const { width, height } = widget.getBoundingClientRect();
    const compact = height < 150;
    const inset = compact ? 16 : Math.min(32, Math.max(20, width * .065));
    const rightInset = compact && widget.ownerDocument.body.classList.contains('widget-window') ? 48 : inset;
    const heightLimit = Math.max(12, (height - inset * 2 - (compact ? 22 : 84)) / 1.2);
    const days = widget.classList.contains('widget-square');
    widget.dataset.layout = compact ? 'compact' : height > width * 1.2 ? 'portrait' : 'standard';
    widget.dataset.narrow = String(width < 280);
    widget.style.setProperty('--inset', `${inset}px`);
    widget.style.setProperty('--number-size', `${Math.min(heightLimit, compact ? 38 : 96, Math.max(12, width - inset - rightInset - 18) * (days ? .28 : .145))}px`);
    onResize({ width, height });
  };
  const observer = new ResizeObserver(update);
  const attributes = new MutationObserver(update);
  observer.observe(widget);
  attributes.observe(widget, { attributes: true, attributeFilter: ['class'] });
  update();
  return () => { observer.disconnect(); attributes.disconnect(); };
}
