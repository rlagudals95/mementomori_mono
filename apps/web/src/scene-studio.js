import './style.css';
import './scene-studio.css';

// Fictional, shared life. No user profile, persistence, or native app changes.
const startedAt = Date.now();
const deadline = startedAt + 1_797_549_297 * 1000;
const lifetime = 83 * 365.2425 * 24 * 60 * 60;
const number = new Intl.NumberFormat('ko-KR');
const systemMotion = matchMedia('(prefers-reduced-motion: reduce)');
const reduceControl = document.querySelector('#reduce-motion');
reduceControl.checked = systemMotion.matches;
const stage = document.querySelector('.scene-stage');
const art = document.querySelector('.scene-art');
const action = document.querySelector('#scene-action');
const message = document.querySelector('#scene-message');
const selector = document.querySelector('.scene-selector');
const list = document.querySelector('.concept-list');
let selected = 0;
let frame;
let clock;
let lastFrame = 0;
let visible = true;
let refs = {};
let resetMessage;
let cycleBoost = 0;
let candleCovered = false;
let fogCleared = false;
let wiping = false;
let wipePointer = null;
let wipePath;
let wipePoints = 0;
const captures = [];
let captureSequence = 0;
const motionAllowed = () => !reduceControl.checked && !systemMotion.matches;
const secondsNow = () => Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
const remainingRatio = () => Math.min(1, Math.max(0, secondsNow() / lifetime));
const elapsed = () => Math.floor((Date.now() - startedAt) / 1000);
const svg = content => `<svg viewBox="0 0 800 350" xmlns="http://www.w3.org/2000/svg">${content}</svg>`;
const miniature = content => `<svg viewBox="0 0 200 120" aria-hidden="true">${content}</svg>`;

function hourglass() {
  const height = 115 * Math.sqrt(remainingRatio());
  const halfWidth = height * .65;
  const baseHeight = 95 * Math.sqrt(1 - remainingRatio());
  return svg(`<defs><pattern id="sand" width="6" height="6" patternUnits="userSpaceOnUse"><circle class="sand-grain" cx="1" cy="1" r=".65"/><circle class="sand-grain" cx="4" cy="4" r=".65"/></pattern></defs>
    <path class="dim hairline" d="M244 320H556"/>
    <g data-ref="glass" style="transform-origin:400px 180px">
      <path d="M311 43H489M311 49H489M311 315H489M311 321H489"/>
      <path d="M325 60H475C475 124 436 142 414 164C405 173 400 176 400 184C400 193 414 201 432 216C462 240 475 268 475 305H325C325 268 338 240 368 216C386 201 400 193 400 184C400 176 395 173 386 164C364 142 325 124 325 60Z"/>
      <path class="dim hairline" d="M315 59V305M485 59V305M332 67C332 113 347 131 363 145M466 264Q470 282 469 298"/>
    </g>
    <g data-ref="sand-content">
      <path d="M${400-halfWidth} ${185-height}H${400+halfWidth}L400 185Z" style="fill:url(#sand);stroke:none"/>
      <path class="hairline" d="M${400-halfWidth} ${185-height}Q400 ${181-height} ${400+halfWidth} ${185-height}"/>
      <path d="M327 304Q355 298 400 ${304-baseHeight}Q445 298 473 304Z" style="fill:url(#sand);stroke:none"/>
      <path class="hairline" d="M327 304Q355 298 400 ${304-baseHeight}Q445 298 473 304"/>
      <circle class="solid" data-ref="grain" cx="400" cy="190" r="1.5"/>
    </g>
    <path class="dim hairline" d="M502 90H553M502 280H553"/>
    <text class="muted" x="565" y="94">아직 남은 것</text><text class="muted" x="565" y="284">이미 살아낸 것</text>`);
}

function sisyphus() {
  return svg(`<path d="M90 302L557 97L653 133"/><path class="dim hairline" d="M104 308L556 109M136 304l9-4M207 273l8-4M281 240l9-4M364 204l10-4M452 166l10-4M607 117l17 7"/>
    <path class="dim" d="M96 294l-4-15m4 15 5-10M626 122l2-16m-2 16 9-9"/>
    <g data-ref="person"><g data-ref="push-pose"><circle cx="-4" cy="-48" r="6"/><path d="M-7-42L-13-34L-39-13M-13-34L12-26L41-31M-9-39L14-33L42-37"/></g><g data-ref="walk-pose"><circle cx="-33" cy="-46" r="6"/><path d="M-34-40L-39-13M-35-32L-50-24L-59-25M-35-32L-24-25L-16-16"/></g><g data-ref="leg-a"><path d="M-39-13L-47-1L-57 0"/></g><g data-ref="leg-b"><path d="M-39-13L-29-6L-22 0L-15 0"/></g></g>
    <g data-ref="rock-position"><g data-ref="rock"><path class="surface" d="M-29-11L-21-27L-1-33L19-26L31-11L32 10L18 27L-3 32L-24 21L-32 3Z"/><path class="dim hairline" d="M-20-17L-5-23L8-18M17 4L8 17L-3 20M-9-3l6-5M-20 6l5 7"/></g></g>
    <text class="muted" x="577" y="78">또, 오늘.</text><path class="muted hairline" d="M569 84l-7 4"/>`);
}

function film() {
  const strip = Array.from({ length: 8 }, (_, i) => {
    const x = i * 150;
    const holes = Array.from({ length: 6 }, (_, n) => `<rect x="${x+n*25+6}" y="94" width="11" height="7" rx="1"/><rect x="${x+n*25+6}" y="249" width="11" height="7" rx="1"/>`).join('');
    return `${holes}<rect class="dim" x="${x+9}" y="111" width="132" height="126" rx="1"/>
      <g class="dim" transform="translate(${x+75} 174)"><circle r="14"/><path d="M0-24V-30M0 24V30M24 0H30M-24 0H-30M17-17l5-5M-17 17l-5 5M17 17l5 5M-17-17l-5-5"/></g>`;
  }).join('');
  return svg(`<defs><clipPath id="film-crop"><rect x="115" y="84" width="570" height="180"/></clipPath></defs>
    <g clip-path="url(#film-crop)"><g data-ref="strip" transform="translate(115 0)"><path d="M-150 85H1350V265H-150Z"/>${strip}</g></g>
    <path d="M316 110V106H329M471 110V106H458M316 236V241H329M471 236V241H458"/>
    <path class="hairline" d="M392 63V80M389 77l3 3 3-3"/><text x="392" y="53" text-anchor="middle">지금, 상영 중</text>
    <rect data-ref="shutter" class="surface" x="115" y="84" width="570" height="181" style="opacity:0;stroke:none"/>
    <g data-ref="prints"></g>`);
}

function candle() {
  const top = 303 - 210 * remainingRatio();
  return svg(`<defs><pattern id="wax" width="8" height="10" patternUnits="userSpaceOnUse"><path class="dim hairline" d="M1 1l1 2M5 8l1 1"/></pattern></defs>
    <path class="dim hairline" stroke-dasharray="3 7" d="M355 86H445M355 86V${top-9}M445 86V${top-9}"/>
    <path class="surface" d="M360 ${top}V299Q400 312 440 299V${top}Z"/>
    <path d="M360 ${top}V299Q400 312 440 299V${top}Z" style="fill:url(#wax);stroke:none"/>
    <ellipse cx="400" cy="${top}" rx="40" ry="8"/>
    <path class="hairline" d="M376 ${top+6}v21q1 9 5 1v-9M427 ${top+5}v36q-1 7-5 1v-24"/>
    <path d="M399 ${top-1}l2-11"/>
    <g data-ref="flame" style="transform-origin:400px ${top-12}px"><path class="solid" d="M400 ${top-12}C374 ${top-23}392 ${top-45}401 ${top-57}C400 ${top-37}420 ${top-34}411 ${top-21}Q407 ${top-14}400 ${top-12}Z"/><path class="surface" style="stroke:none" d="M400 ${top-16}Q390 ${top-23}401 ${top-36}Q412 ${top-24}400 ${top-16}Z"/></g>
    <path d="M329 308Q400 325 471 308M329 308Q328 337 400 337Q472 337 471 308M343 323Q400 341 457 323"/>
    <g class="muted hairline"><path d="M486 87H496M491 87V303M486 303H496M486 ${top}H505"/><text x="520" y="${top+4}">남아 있는 초</text></g>
    <g data-ref="cover" style="opacity:0"><path class="surface" d="M276 ${top+3}Q278 ${top-21}308 ${top-27}L338 ${top-52}Q342 ${top-58}348 ${top-54}Q353 ${top-50}347 ${top-43}L334 ${top-26}L369 ${top-57}Q375 ${top-62}379 ${top-55}Q382 ${top-51}376 ${top-45}L353 ${top-21}L383 ${top-39}Q391 ${top-43}393 ${top-35}Q393 ${top-31}386 ${top-27}L365 ${top-12}L387 ${top-17}Q397 ${top-17}395 ${top-9}Q394 ${top-5}385 ${top-3}L347 ${top+8}L315 ${top+22}Z"/><path class="dim hairline" d="M296 ${top+3}q18-7 36-1"/></g>`);
}

function train() {
  return svg(`<defs><clipPath id="window-crop"><rect x="159" y="54" width="482" height="235" rx="20"/></clipPath><mask id="fog-mask" maskUnits="userSpaceOnUse" x="158" y="53" width="485" height="238"><rect x="158" y="53" width="485" height="238" fill="white" stroke="none"/><g data-ref="wipe-marks" fill="none" stroke="black" stroke-width="38" stroke-linecap="round"></g></mask></defs>
    <rect x="140" y="35" width="520" height="275" rx="31"/><rect x="149" y="45" width="502" height="254" rx="25" class="dim"/>
    <g clip-path="url(#window-crop)">
      <path class="dim" d="M159 191L206 161L251 174L305 116L359 151L408 132L490 188L554 140L641 180"/>
      <g data-ref="hills" class="muted"><path d="M-60 245Q56 173 182 215T424 212T675 220T933 205T1180 225"/><path class="dim hairline" d="M-60 250H1180"/></g>
      <g data-ref="cloud" class="dim hairline"><path d="M245 95h63m-50-6h42M496 108h38m-30-6h20"/></g>
      <g data-ref="pole"><path d="M0 104V289M-24 123H24M-18 134H18M-17 121V115M17 121V115"/><path class="hairline" d="M-250 114Q-125 151 0 122Q125 156 250 113"/></g>
      <g data-ref="fog" mask="url(#fog-mask)"><rect class="surface" x="158" y="53" width="485" height="238" style="opacity:.65;stroke:none"/><g class="dim hairline" style="opacity:.6"><path d="M183 92l0 12M199 163v11M216 243v11M596 101v11M619 227v12M505 248v9M257 76v8M324 251v6"/><path d="M281 161q20-24 43-3m139 10q28-24 46-6"/></g><text class="muted" x="400" y="184" text-anchor="middle">손끝으로, 창밖을.</text></g>
    </g>
    <path class="dim hairline" d="M285 331H515"/><text class="muted tiny" x="400" y="342" text-anchor="middle">ONE WAY / 편도</text>`);
}

const scenes = [
  { name: '모래시계', title: '뒤집을 수 없는 시간.', code: 'THE HOURGLASS', category: '01 / 쌓임', message: '위에는 살아갈 시간. 아래에는 살아낸 시간.', action: '뒤집어 보기', hint: '모래의 양은 수명의 비율입니다.', summary: '흘러간 시간이 사라지지 않고, 살아낸 시간으로 쌓입니다.', build: hourglass,
    thumbnail: miniature('<path d="M76 16h48M76 103h48M80 22h40q0 23-14 34-6 4 0 9 14 14 14 32H80q0-18 14-32 6-5 0-9-14-11-14-34Z"/><path class="solid" d="M84 34h32l-16 27ZM82 97l18-18 18 18Z"/><path stroke-dasharray="1 4" d="M100 65v12"/>') },
  { name: '시지프스', title: '또, 오늘의 돌을 민다.', code: 'THE EVERYDAY CLIMB', category: '02 / 반복', message: '돌은 다시 굴러도, 오늘을 살아낸 당신은 남습니다.', action: '한 번 더 밀기', hint: '돌의 반복과 삶의 시간은 다르게 흐릅니다.', summary: '삶은 반복되어 보여도, 그 안의 오늘은 한 번뿐입니다.', build: sisyphus,
    thumbnail: miniature('<path d="M28 101L148 35l31 13"/><circle cx="117" cy="37" r="18"/><path d="M111 24l9 3 6 9M107 43l5 5"/><circle cx="79" cy="55" r="4"/><path d="M77 60l-6 13-12 11m14-16 10 6 10-6M59 84l-10 7-7 1m17-8 5 5 12-4"/>') },
  { name: '필름', title: '한 번만 상영되는 영화.', code: 'THE ONE-TAKE FILM', category: '03 / 기록', message: '되감기는 없습니다. 남기고 싶은 장면은 있습니다.', action: '한 컷 남기기', hint: '이 화면에서만 장면을 남깁니다.', summary: '흘러가는 초를, 기억하고 싶은 장면으로 바꿉니다.', build: film,
    thumbnail: miniature('<path d="M18 30h164v60H18Z"/><path d="M65 30v60M135 30v60"/><rect x="75" y="43" width="50" height="34"/><circle cx="100" cy="60" r="8"/><path stroke-dasharray="4 8" d="M23 35H178M23 85H178"/>') },
  { name: '촛불', title: '초가 줄어드는 초.', code: 'THE LIVING CANDLE', category: '04 / 소모', message: '한 초, 한 초. 당신의 오늘을 밝히는 중.', action: '불꽃 가려보기', hint: '가려도 숫자는 계속 줄어듭니다.', summary: '시간은 없어지는 동시에, 지금의 삶을 밝힙니다.', build: candle,
    thumbnail: miniature('<path d="M85 53v45q15 7 30 0V53"/><ellipse cx="100" cy="53" rx="15" ry="3"/><path d="M100 52v-7"/><path class="solid" d="M100 43q-16-7 2-28-1 9 5 14 6 9-7 14Z"/><path d="M72 101q28 13 56 0M72 101q1 13 28 13t28-13"/>') },
  { name: '편도 열차', title: '당신의 삶은 편도입니다.', code: 'THE ONE-WAY WINDOW', category: '05 / 여정', message: '다시 지나갈 수 없는 풍경. 지금, 창밖을 바라보세요.', action: '창문 닦기', hint: '창문을 직접 드래그해서 닦아도 됩니다.', summary: '앞만 보다가 놓친 지금의 풍경을, 잠깐 발견합니다.', build: train,
    thumbnail: miniature('<rect x="36" y="17" width="128" height="87" rx="11"/><rect x="42" y="23" width="116" height="75" rx="8"/><path d="M44 74l25-25 17 11 26-24 43 30M44 83h111M121 43v43m-9-30h18"/>') },
];

// Build the selection UI from the same descriptions used by the stage.
scenes.forEach((scene, index) => {
  const tab = document.createElement('button');
  tab.className = 'scene-tab'; tab.id = `scene-tab-${index}`;
  tab.setAttribute('role', 'tab'); tab.setAttribute('aria-controls', 'scene-panel');
  tab.innerHTML = `<small>0${index+1}</small><span>${scene.name}</span>`;
  tab.addEventListener('click', () => selectScene(index));
  tab.addEventListener('keydown', event => {
    let next;
    if (event.key === 'ArrowRight') next = (selected + 1) % scenes.length;
    if (event.key === 'ArrowLeft') next = (selected + scenes.length - 1) % scenes.length;
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = scenes.length - 1;
    if (next === undefined) return;
    event.preventDefault(); selectScene(next); selector.children[next].focus();
  });
  selector.append(tab);
  const entry = document.createElement('button'); entry.className = 'concept-entry';
  entry.innerHTML = `<span class="concept-art">${scene.thumbnail}</span><small>0${index+1} / ${scene.category.split(' / ')[1]}</small><strong>${scene.name}</strong><span>${scene.summary}</span>`;
  entry.addEventListener('click', () => {
    selectScene(index);
    selector.children[index].focus({ preventScroll: true });
    selector.scrollIntoView({ behavior: motionAllowed() ? 'smooth' : 'instant', block: 'start' });
  });
  list.append(entry);
});

function cancelEffects() {
  clearTimeout(resetMessage);
  art.querySelectorAll('*').forEach(element => element.getAnimations().forEach(animation => animation.cancel()));
  candleCovered = false; wiping = false; wipePointer = null;
  if (refs.flame) refs.flame.style.opacity = '1';
  if (refs.cover) refs.cover.style.opacity = '0';
  if (refs.shutter) refs.shutter.style.opacity = '0';
}

function selectScene(index) {
  cancelEffects(); selected = index; cycleBoost = 0; fogCleared = false;
  const scene = scenes[index];
  [...selector.children].forEach((tab, i) => { tab.setAttribute('aria-selected', String(i === index)); tab.tabIndex = i === index ? 0 : -1; });
  [...list.children].forEach((entry, i) => entry.setAttribute('aria-pressed', String(i === index)));
  document.querySelector('#scene-panel').setAttribute('aria-labelledby', `scene-tab-${index}`);
  document.querySelector('#scene-code').textContent = `0${index+1} / ${scene.code}`;
  document.querySelector('#scene-category').textContent = scene.category;
  document.querySelector('#scene-title').textContent = scene.title;
  message.textContent = scene.message;
  action.textContent = scene.action;
  document.querySelector('#scene-hint').textContent = scene.hint;
  art.innerHTML = scene.build();
  art.classList.toggle('train-scene', index === 4);
  refs = Object.fromEntries([...art.querySelectorAll('[data-ref]')].map(element => [element.dataset.ref, element]));
  if (index === 2) renderCaptures();
  if (index === 4) setupWiping();
  renderScene(motionAllowed() ? (Date.now()-startedAt)/1000 : 2);
  updateClock(); scheduleMotion();
}

function effect(element, frames, options = {}) {
  if (!element || !motionAllowed()) return;
  element.getAnimations().forEach(animation => animation.cancel());
  return element.animate(frames, { duration: 420, easing: 'cubic-bezier(.25,1,.5,1)', ...options });
}

function renderScene(t) {
  if (selected === 0) {
    const endY = 304 - 95 * Math.sqrt(1 - remainingRatio());
    const fall = (t % 1) ** 1.6;
    refs.grain.setAttribute('transform', `translate(0 ${fall * (endY-192)})`);
    refs.grain.style.opacity = String(.9 - .5 * fall);
  }
  if (selected === 1) {
    const phase = ((t + cycleBoost) % 20) / 20;
    let personX, rockX;
    if (phase < .56) { personX = 153 + phase / .56 * 350; rockX = personX + 54; }
    else if (phase < .7) { personX = 503; rockX = 557 - ((phase-.56)/.14) ** 1.8 * 350; }
    else { personX = 503 - (phase-.7)/.3 * 350; rockX = 207; }
    const ground = x => 302 - (x-90) * 205/467;
    refs.person.setAttribute('transform', `translate(${personX} ${ground(personX)}) rotate(-23.7)`);
    refs['rock-position'].setAttribute('transform', `translate(${rockX} ${ground(rockX)-34})`);
    refs.rock.setAttribute('transform', `rotate(${(rockX-207)/32*180/Math.PI})`);
    const walking = phase < .56 || phase > .7;
    const step = walking ? Math.sin(t * 5) * 12 : 0;
    refs['push-pose'].style.opacity = phase > .7 ? '0' : '1';
    refs['walk-pose'].style.opacity = phase > .7 ? '1' : '0';
    refs['leg-a'].setAttribute('transform', `rotate(${step} -39 -13)`);
    refs['leg-b'].setAttribute('transform', `rotate(${-step} -39 -13)`);
  }
  if (selected === 2) refs.strip.setAttribute('transform', `translate(${115 - (t % 10)/10 * 150} 0)`);
  if (selected === 3) {
    refs.flame.style.transform = `rotate(${Math.sin(t*2.3)*3}deg) scaleX(${.96+Math.sin(t*1.7)*.04})`;
    refs.flame.style.opacity = candleCovered ? '.05' : String(.94+Math.sin(t*1.5)*.06);
  }
  if (selected === 4) {
    refs.hills.setAttribute('transform', `translate(${-t % 30 / 30 * 240} 0)`);
    refs.cloud.setAttribute('transform', `translate(${Math.sin(t*.06)*14} 0)`);
    refs.pole.setAttribute('transform', `translate(${740 - t % 8 / 8 * 700} 0)`);
  }
}

function animateFrame(now) {
  frame = null;
  if (document.hidden || !visible || !motionAllowed()) return;
  if (now - lastFrame >= 1000/30) { renderScene((Date.now()-startedAt)/1000); lastFrame = now; }
  frame = requestAnimationFrame(animateFrame);
}
function scheduleMotion() {
  cancelAnimationFrame(frame); frame = null;
  if (!document.hidden && visible && motionAllowed()) frame = requestAnimationFrame(animateFrame);
}
function updateClock() {
  document.querySelector('#seconds').textContent = number.format(secondsNow());
  document.querySelector('#life-fraction').textContent = `남은 삶 ${(remainingRatio()*100).toFixed(1)}%\n예시 · 83년`;
}
function renderCaptures() {
  refs.prints.innerHTML = captures.slice(-3).map((capture, i) => `<g transform="translate(${267+i*98} 286)"><rect class="muted hairline" x="0" y="0" width="78" height="36"/><path class="dim hairline" d="M9 26l11-12 11 5 10-9 12 16"/><text class="tiny" x="39" y="51" text-anchor="middle">#${String(capture.id).padStart(2,'0')} / +${capture.elapsed}초</text></g>`).join('');
}

action.addEventListener('click', () => {
  clearTimeout(resetMessage);
  if (selected === 0) {
    // The symmetric frame turns; the real amount of time cannot be refilled.
    effect(refs.glass, [{ transform: 'rotate(0deg)' }, { transform: 'rotate(180deg)' }], { duration: 460 });
    message.textContent = '뒤집어도, 지나간 초는 돌아오지 않습니다.';
  }
  if (selected === 1) {
    cycleBoost += 1.4;
    renderScene(motionAllowed() ? (Date.now()-startedAt)/1000 : 2);
    message.textContent = '다시 밀어 올리는 것. 그것도 오늘의 선택입니다.';
  }
  if (selected === 2) {
    captures.push({ id: ++captureSequence, elapsed: elapsed() });
    if (captures.length > 3) captures.shift();
    renderCaptures();
    effect(refs.shutter, [{ opacity: .7 }, { opacity: 0 }], { duration: 180 });
    message.textContent = `함께 보낸 ${elapsed()}초의 장면을 남겼습니다. 영화는 계속됩니다.`;
  }
  if (selected === 3) {
    candleCovered = true; refs.cover.style.opacity = '1'; refs.flame.style.opacity = '.05';
    effect(refs.cover, [{ opacity: 0, transform: 'translateX(-12px)' }, { opacity: 1, transform: 'translateX(0)' }], { duration: 240 });
    message.textContent = '불꽃을 가려도, 초는 줄어듭니다.';
    resetMessage = setTimeout(() => {
      candleCovered = false; refs.cover.style.opacity = '0'; refs.flame.style.opacity = '1';
      effect(refs.cover, [{ opacity: 1 }, { opacity: 0 }], { duration: 180 });
    }, 2200);
  }
  if (selected === 4) {
    fogCleared = !fogCleared; refs.fog.style.opacity = fogCleared ? '0' : '1';
    effect(refs.fog, [{ opacity: fogCleared ? 1 : 0 }, { opacity: fogCleared ? 0 : 1 }], { duration: 320 });
    if (!fogCleared) refs['wipe-marks'].replaceChildren();
    action.textContent = fogCleared ? '다시 김 서리기' : '창문 닦기';
    message.textContent = fogCleared ? '도착만 기다리기엔, 지금의 풍경이 아깝습니다.' : scenes[4].message;
  }
});

function setupWiping() {
  const surface = art.querySelector('svg');
  const point = event => {
    const matrix = surface.getScreenCTM();
    return matrix ? new DOMPoint(event.clientX, event.clientY).matrixTransform(matrix.inverse()) : null;
  };
  surface.addEventListener('pointerdown', event => {
    if (event.button !== 0 || fogCleared) return;
    const p = point(event);
    if (!p || p.x<159 || p.x>641 || p.y<54 || p.y>289) return;
    surface.setPointerCapture(event.pointerId); wiping = true; wipePointer = event.pointerId; wipePoints = 0;
    // Bound mask complexity even during a long drawing session.
    if (refs['wipe-marks'].children.length >= 24) refs['wipe-marks'].firstElementChild.remove();
    wipePath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    wipePath.setAttribute('d', `M${p.x.toFixed(1)} ${p.y.toFixed(1)}l.1 .1`);
    refs['wipe-marks'].append(wipePath);
    message.textContent = '지금 보고 있는 이 풍경도, 곧 지나갑니다.';
  });
  surface.addEventListener('pointermove', event => {
    if (!wiping || event.pointerId !== wipePointer || wipePoints >= 150) return;
    const p = point(event); if (!p) return;
    wipePath.setAttribute('d', `${wipePath.getAttribute('d')}L${p.x.toFixed(1)} ${p.y.toFixed(1)}`); wipePoints++;
  });
  const finish = event => { if (event.pointerId === wipePointer) { wiping = false; wipePointer = null; } };
  surface.addEventListener('pointerup', finish); surface.addEventListener('pointercancel', finish); surface.addEventListener('lostpointercapture', finish);
}

function updateMotionPreference() {
  cancelEffects();
  document.body.classList.toggle('motion-reduced', !motionAllowed());
  if (!motionAllowed()) renderScene(2);
  scheduleMotion();
}
reduceControl.addEventListener('change', updateMotionPreference);
systemMotion.addEventListener('change', () => { if (systemMotion.matches) reduceControl.checked = true; updateMotionPreference(); });
document.querySelectorAll('[data-theme]').forEach(button => button.addEventListener('click', () => {
  stage.classList.toggle('light', button.dataset.theme === 'light');
  document.querySelectorAll('[data-theme]').forEach(option => option.setAttribute('aria-pressed', String(option === button)));
}));
const observer = new IntersectionObserver(entries => { visible = entries[0].isIntersecting; scheduleMotion(); });
observer.observe(stage);
function resumeClock() { clearInterval(clock); updateClock(); clock = setInterval(updateClock, 250); }
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { clearInterval(clock); cancelAnimationFrame(frame); cancelEffects(); }
  else { resumeClock(); scheduleMotion(); }
});
window.addEventListener('pagehide', () => { clearInterval(clock); cancelAnimationFrame(frame); observer.disconnect(); cancelEffects(); });
window.addEventListener('pageshow', event => { if (event.persisted) { observer.observe(stage); resumeClock(); scheduleMotion(); } });
selectScene(0); updateMotionPreference(); resumeClock();
