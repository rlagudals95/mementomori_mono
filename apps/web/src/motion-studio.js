import './style.css';
import './motion-studio.css';

// A shared fictional deadline. This study never reads or writes a real profile.
const deadline = Date.now() + 1_797_549_297 * 1000;
const number = new Intl.NumberFormat('ko-KR');
const systemMotion = matchMedia('(prefers-reduced-motion: reduce)');
const motionControl = document.querySelector('#reduce-motion');
motionControl.checked = systemMotion.matches;
const widgets = [...document.querySelectorAll('.motion-widget')];
const motionAllowed = () => !systemMotion.matches && !motionControl.checked;
const secondsNow = () => Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
let currentSeconds = null;
let timer;

widgets.forEach(widget => {
  widget.innerHTML = `<span class="mw-top"><span>mementomori.</span><span class="mw-monogram">M / M</span></span>
    <span class="mw-time"><span class="mw-caption">당신의 시간은 유한합니다.</span>
    <span class="mw-number"><span class="mw-digits" aria-live="off"></span><span class="mw-unit">초</span></span></span>
    <span class="mw-horizon" aria-hidden="true"><span class="mw-past"></span><span class="mw-now"></span><span class="mw-pulse"></span><span class="mw-end"></span></span>
    <span class="mw-foot"><span class="mw-thought">이 1초는 돌아오지 않습니다.</span><span class="mw-percent">31%</span></span>`;
  widget.visible = true;
  widget.lastDigits = '';
});

function animate(element, frames, options) {
  if (!motionAllowed()) return null;
  return element.animate(frames, { easing: 'cubic-bezier(.25,1,.5,1)', ...options });
}

function renderNumber(widget, text, useMotion) {
  const container = widget.querySelector('.mw-digits');
  container.setAttribute('aria-label', `${text}초`);
  if (widget.lastDigits.length !== text.length) {
    container.replaceChildren(...[...text].map(char => {
      const digit = document.createElement('span'); digit.className = 'digit';
      const value = document.createElement('span'); value.className = 'digit-value'; value.textContent = char;
      digit.append(value); return digit;
    }));
  } else {
    [...text].forEach((char, index) => {
      const digit = container.children[index];
      const value = digit.querySelector('.digit-value');
      if (value.textContent === char) return;
      if (useMotion && widget.dataset.motion === 'dissolve' && motionAllowed()) {
        const ghost = document.createElement('span'); ghost.className = 'digit-ghost'; ghost.textContent = value.textContent;
        ghost.setAttribute('aria-hidden', 'true'); digit.append(ghost);
        const fade = animate(ghost, [{ opacity: .38, transform: 'translateY(0)' }, { opacity: 0, transform: 'translateY(9px)' }], { duration: 380 });
        fade?.finished.then(() => ghost.remove()).catch(() => ghost.remove());
        animate(value, [{ opacity: .5 }, { opacity: 1 }], { duration: 230 });
      }
      value.textContent = char;
    });
  }
  widget.lastDigits = text;
}

function ripple(widget, touched = false) {
  const pulse = widget.querySelector('.mw-pulse');
  pulse.getAnimations().forEach(animation => animation.cancel());
  animate(pulse, [
    { opacity: touched ? .6 : .16, transform: 'scale(.18)' },
    { opacity: 0, transform: `scale(${touched ? 2.1 : 1.05})` },
  ], { duration: touched ? 480 : 650 });
}

function tick() {
  const value = secondsNow();
  if (value === currentSeconds) return;
  const continuous = currentSeconds - value === 1;
  const text = number.format(value);
  widgets.forEach(widget => {
    renderNumber(widget, text, continuous && widget.visible);
    if (continuous && widget.visible && widget.dataset.motion === 'ripple') ripple(widget);
  });
  currentSeconds = value;
}

const dissolve = widgets.find(widget => widget.dataset.motion === 'dissolve');
dissolve.addEventListener('click', () => {
  const digit = [...dissolve.querySelectorAll('.digit')].at(-1);
  if (!motionAllowed()) return;
  const ghost = document.createElement('span'); ghost.className = 'digit-ghost';
  ghost.textContent = String((Number(digit.querySelector('.digit-value').textContent) + 1) % 10); ghost.setAttribute('aria-hidden', 'true'); digit.append(ghost);
  animate(ghost, [{ opacity: .72, transform: 'translateY(0)' }, { opacity: 0, transform: 'translateY(12px)' }], { duration: 420 })
    ?.finished.then(() => ghost.remove()).catch(() => ghost.remove());
});
widgets.find(widget => widget.dataset.motion === 'ripple').addEventListener('click', event => ripple(event.currentTarget, true));

const moment = widgets.find(widget => widget.dataset.motion === 'moment');
const momentText = moment.querySelector('.mw-thought');
let releasing;
function captureMoment() {
  clearTimeout(releasing); momentText.getAnimations().forEach(animation => animation.cancel());
  moment.classList.add('holding');
  momentText.textContent = `바라본 순간 ${number.format(secondsNow())}초`;
}
function releaseMoment() {
  if (!moment.classList.contains('holding')) return;
  moment.classList.remove('holding');
  releasing = setTimeout(() => {
    if (!motionAllowed()) { momentText.textContent = '이 1초는 돌아오지 않습니다.'; return; }
    const fade = animate(momentText, [{ opacity: 1 }, { opacity: 0 }], { duration: 280 });
    fade?.finished.then(() => {
      momentText.textContent = '이 1초는 돌아오지 않습니다.';
      animate(momentText, [{ opacity: 0 }, { opacity: 1 }], { duration: 240 });
    }).catch(() => {});
  }, 1200);
}
moment.addEventListener('pointerdown', event => {
  if (event.button !== 0) return;
  moment.setPointerCapture(event.pointerId); captureMoment();
});
moment.addEventListener('pointerup', releaseMoment);
moment.addEventListener('pointercancel', releaseMoment);
moment.addEventListener('lostpointercapture', releaseMoment);
moment.addEventListener('keydown', event => { if (event.code === 'Space') { event.preventDefault(); if (!event.repeat) captureMoment(); } });
moment.addEventListener('keyup', event => { if (event.code === 'Space') { event.preventDefault(); releaseMoment(); } });
moment.addEventListener('blur', releaseMoment);
moment.addEventListener('click', event => { if (event.detail === 0 && !moment.classList.contains('holding')) { captureMoment(); releaseMoment(); } });

function cancelMotion() {
  widgets.forEach(widget => {
    widget.getAnimations({ subtree: true }).forEach(animation => animation.cancel());
    widget.querySelectorAll('.digit-ghost').forEach(ghost => ghost.remove());
  });
  if (!moment.classList.contains('holding')) momentText.textContent = '이 1초는 돌아오지 않습니다.';
}
motionControl.addEventListener('change', cancelMotion);
systemMotion.addEventListener('change', () => { if (systemMotion.matches) motionControl.checked = true; cancelMotion(); });
document.querySelectorAll('[data-theme]').forEach(button => button.addEventListener('click', () => {
  const light = button.dataset.theme === 'light';
  widgets.forEach(widget => widget.classList.toggle('light', light));
  document.querySelectorAll('[data-theme]').forEach(option => option.setAttribute('aria-pressed', String(option === button)));
}));

const observer = new IntersectionObserver(entries => entries.forEach(entry => { entry.target.visible = entry.isIntersecting; }));
widgets.forEach(widget => observer.observe(widget));
function resume() { clearInterval(timer); tick(); timer = setInterval(tick, 100); }
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { clearInterval(timer); cancelMotion(); releaseMoment(); }
  else resume();
});
window.addEventListener('pagehide', () => { clearInterval(timer); clearTimeout(releasing); observer.disconnect(); cancelMotion(); });
resume();
