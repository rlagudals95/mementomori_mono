import './style.css';
import './scene-studio.css';

// All interests share one fictional life; no profile or storage is accessed.
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
let vinylPaused = false;
let vinylAngle = 0;
let vinylUpdatedAt = 0;
let bookmarkSet = false;
let treeFocused = false;
const motionAllowed = () => !reduceControl.checked && !systemMotion.matches;
const secondsNow = () => Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
const remainingRatio = () => Math.min(1, Math.max(0, secondsNow() / lifetime));
const livedYears = () => 83 * (1 - remainingRatio());
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

function record() {
  const radius = 52 + remainingRatio() * 86;
  const x = 365 + Math.cos(-.6) * radius;
  const y = 175 + Math.sin(-.6) * radius;
  const grooves = Array.from({length:17}, (_,i) => `<circle class="${55+i*5>radius?'dim':'muted'} hairline" cx="365" cy="175" r="${55+i*5}"/>`).join('');
  return svg(`<rect class="dim hairline" x="188" y="20" width="440" height="310" rx="3"/>
    <circle cx="365" cy="175" r="145"/><circle class="dim" cx="365" cy="175" r="141"/>${grooves}
    <g data-ref="record" style="transform-origin:365px 175px">
      <path class="muted hairline" d="M257 104A130 130 0 0 1 289 65M280 111A109 109 0 0 1 302 87M470 239A124 124 0 0 1 446 270"/>
      <circle class="surface" cx="365" cy="175" r="49"/><circle class="dim hairline" cx="365" cy="175" r="45"/>
      <text x="365" y="155" text-anchor="middle" style="font-size:10px;font-weight:650">THIS LIFE</text>
      <text class="muted tiny" x="365" y="199" text-anchor="middle">SIDE A / ONCE</text>
      <circle class="solid" cx="365" cy="175" r="3"/>
    </g>
    <circle class="surface" cx="571" cy="67" r="20"/><circle cx="571" cy="67" r="12"/>
    <path d="M571 67L548 101L${x+12} ${y-8}" style="stroke-width:5"/><path class="surface" d="M${x+12} ${y-14}l-18 10 7 12 18-10Z"/>
    <circle class="solid" cx="${x}" cy="${y}" r="2.2"/>
    <rect class="dim hairline" x="558" y="268" width="38" height="34" rx="2"/>
    <g data-ref="record-icon"><path d="M571 278V292M582 278V292"/></g>
    <text class="muted tiny" x="578" y="245" text-anchor="middle">한 번뿐인 트랙</text>
    <path class="dim hairline" d="M206 307H236"/><circle class="solid" cx="214" cy="307" r="1.5"/>`);
}

function book() {
  const chapter = Math.min(83, Math.floor(livedYears())+1);
  const writing = [93,119,106,112,82,120,97].map((length,i) => `<path class="muted hairline" d="M255 ${143+i*13}h${length}"/>`).join('');
  return svg(`<path class="dim hairline" d="M208 301H592"/>
    <path d="M226 84V273Q310 267 400 288Q490 267 574 273V84"/>
    <path class="dim hairline" d="M233 269Q315 262 400 283Q485 262 567 269M233 275Q315 268 400 289Q485 268 567 275"/>
    <path class="surface" d="M235 80Q318 67 400 93V276Q318 254 235 266Z"/>
    <path class="surface" d="M400 93Q482 67 565 80V266Q482 254 400 276Z"/>
    <path class="dim hairline" d="M394 97V271M406 97V271"/>
    <text class="muted tiny" x="255" y="119">살아낸 이야기</text>${writing}
    <text x="486" y="146" text-anchor="middle" style="font-size:34px;font-weight:650;letter-spacing:-.04em">제${chapter}장</text>
    <text class="muted" x="486" y="184" text-anchor="middle">이 페이지는 아직</text><text class="muted" x="486" y="205" text-anchor="middle">쓰는 중입니다.</text>
    <path class="dim hairline" d="M444 232H526"/><path data-ref="cursor" d="M444 225V235"/>
    <text class="muted tiny" x="317" y="253" text-anchor="middle">${chapter-1}</text><text class="muted tiny" x="485" y="253" text-anchor="middle">${chapter} / 83</text>
    <g data-ref="bookmark" style="opacity:0;transform-origin:514px 73px"><path class="surface" d="M505 76Q514 74 523 75V127L514 119L505 127Z"/><path class="muted hairline" d="M514 77V113"/></g>
    <path class="dim hairline" d="M547 79V98L565 96"/>`);
}

// Nested, imperfect rings retain an organic outline without random crossings.
function ringPath(radius) {
  const points = Array.from({length:97}, (_, i) => {
    const angle = i/96 * Math.PI*2;
    const r = radius * (1 + .035*Math.sin(angle*3+.5) + .022*Math.sin(angle*7) + .015*Math.sin(angle*11+.3));
    return `${i===0?'M':'L'}${(400+Math.cos(angle)*r).toFixed(2)} ${(175+Math.sin(angle)*r).toFixed(2)}`;
  });
  return `${points.join('')}Z`;
}
function tree() {
  const age = livedYears();
  const rings = Array.from({length:83},(_,i) => `<path ${i+1>age?'class="dim"':''} d="${ringPath(12+(i+1)*1.47)}" style="stroke-width:${i+1>age?.5:.75}"/>`).join('');
  const currentRadius = 12 + age*1.47;
  return svg(`<g data-ref="tree" style="transform-origin:400px 175px">
      <path d="${ringPath(140)}"/><path class="dim" d="${ringPath(145)}"/>
      ${rings}<path data-ref="growth-ring" d="${ringPath(currentRadius)}"/>
      <path class="dim hairline" d="M391 180L370 154L358 151M370 154L369 136M446 277l13 21M473 113l13-10"/>
      <circle class="solid" data-ref="growth-dot" cx="${400+currentRadius*1.03}" cy="175" r="2.2"/>
      <text x="400" y="175" text-anchor="middle" style="font-size:21px;font-weight:600">${age.toFixed(1)}</text><text class="muted tiny" x="400" y="193" text-anchor="middle">살아온 해</text>
    </g>
    <path class="dim hairline" d="M555 144H586M555 203H586"/>
    <text class="muted" x="600" y="148">살아온 나이테</text><text class="muted" x="600" y="207">앞으로의 자리</text>
    <path class="muted hairline" d="M223 98Q245 67 276 63M245 76Q234 58 242 46Q258 54 253 68M261 66Q261 47 277 42Q283 60 269 64"/>`);
}

function game() {
  const segments = Array.from({length:24},(_,i) => `<rect x="${220+i*15}" y="101" width="11" height="18"/>`).join('');
  const x = 218+(1-remainingRatio())*370;
  return svg(`<defs><clipPath id="life-fill"><rect x="220" y="101" width="${remainingRatio()*360}" height="18"/></clipPath></defs>
    <text x="210" y="74" style="font-size:13px;font-weight:700;letter-spacing:.12em">ONE LIFE</text><text class="muted tiny" x="590" y="74" text-anchor="end">NO RESTART</text>
    <g class="solid" transform="translate(157 95) scale(3)"><path d="M0 2H2V0H6V2H8V0H12V2H14V6H12V8H10V10H8V12H6V10H4V8H2V6H0Z"/></g>
    <rect x="210" y="91" width="380" height="38"/>
    <g class="dim" style="stroke-width:.65">${segments}</g><g class="solid" clip-path="url(#life-fill)">${segments}</g>
    <path class="dim hairline" d="M209 275H610M209 281H610"/>
    <g class="dim hairline"><path d="M213 292h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7m15 0h7"/></g>
    <g transform="translate(${x} 272)"><g data-ref="runner" style="transform-origin:0 0">
      <g class="solid" transform="translate(-9 -40) scale(2)"><path d="M2 0H8V1H9V6H7V7H10V9H8V12H2V9H0V7H3V6H1V1H2Z"/><g data-ref="game-leg-a"><path d="M2 12H5V18H1V16H2Z"/></g><g data-ref="game-leg-b"><path d="M5 12H8V16H10V18H6V15H5Z"/></g></g>
    </g></g>
    <path d="M596 272V240H615V272M594 237H618"/><path class="dim hairline" d="M600 244H611V272"/>
    <text class="muted tiny" x="401" y="321" text-anchor="middle">남은 생명은 충전되지 않습니다.</text>`);
}

const scenes = [
  { name:'모래시계', interest:'기본', title:'뒤집을 수 없는 시간.', code:'THE HOURGLASS', message:'위에는 살아갈 시간. 아래에는 살아낸 시간.', action:'뒤집어 보기', hint:'모래의 양은 수명의 비율입니다.', summary:'남은 시간과 살아낸 시간을 가장 직접적으로 느끼는 기본 장면.', build:hourglass,
    thumbnail:miniature('<path d="M76 16h48M76 103h48M80 22h40q0 23-14 34-6 4 0 9 14 14 14 32H80q0-18 14-32 6-5 0-9-14-11-14-34Z"/><path class="solid" d="M84 34h32l-16 27ZM82 97l18-18 18 18Z"/><path stroke-dasharray="1 4" d="M100 65v12"/>') },
  { name:'음악', object:'레코드', interest:'음악 · 레코드', title:'당신만의 트랙, 한 번의 재생.', code:'THE LIFE RECORD', message:'곡에는 끝이 있고, 아직 들을 부분이 남아있습니다.', action:'잠깐 멈춰 보기', hint:'소리 없는 시각 시안입니다. 숫자는 계속 흐릅니다.', summary:'남은 삶은 남은 트랙. 바늘이 천천히 안쪽을 향하는 레코드.', build:record,
    thumbnail:miniature('<rect x="35" y="12" width="130" height="96" rx="2"/><circle cx="88" cy="60" r="41"/><circle cx="88" cy="60" r="34"/><circle cx="88" cy="60" r="27"/><circle cx="88" cy="60" r="14"/><circle class="solid" cx="88" cy="60" r="2"/><circle cx="149" cy="27" r="7"/><path d="M149 27l-10 16-25 4m0-4 2 8"/>') },
  { name:'독서', object:'인생의 책', interest:'독서 · 글쓰기', title:'아직 쓰지 않은 이야기가 있다.', code:'THE UNWRITTEN BOOK', message:'살아온 장도, 앞으로 써 내려갈 장도 한 권의 당신입니다.', action:'책갈피 꽂기', hint:'한 장을 삶의 1년으로 표현한 가상의 83장입니다.', summary:'이미 쓴 장과 아직 쓸 장. 한 권의 책으로 바라보는 삶.', build:book,
    thumbnail:miniature('<path d="M43 28q29-5 57 6 28-11 57-6v66q-29-5-57 6-28-11-57-6ZM100 34v66"/><path d="M38 30v69q30-5 62 7 32-12 62-7V30"/><path d="M52 46h34m-34 9h31m-31 9h33m-33 9h24M124 29v27l5-4 5 4V28"/>') },
  { name:'자연', object:'삶의 나이테', interest:'자연 · 나무', title:'살아낸 만큼, 당신 안에 남는다.', code:'THE LIFE RINGS', message:'선명한 나이테는 살아온 해. 옅은 나이테는 앞으로의 자리.', action:'나이테 자세히 보기', hint:'가상의 83년을 83개의 나이테로 표현합니다.', summary:'시간이 줄어드는 동시에, 살아낸 경험이 안쪽에 쌓이는 나무.', build:tree,
    thumbnail:miniature('<path d="M147 61q5 40-43 46-43 0-52-39-8-46 41-53 46-5 54 46Z"/><path d="M138 62q2 33-36 35-34 0-40-31-7-36 32-41 34-5 44 37ZM126 63q2 22-25 24-23-1-26-22-5-27 21-29 23-3 30 27ZM112 63q1 11-13 13-12-1-13-12-2-13 11-16 13-1 15 15Z"/><path d="M155 34q5-14 19-15m-10 7q-8-8-3-15 10 3 8 11"/>') },
  { name:'게임', object:'한 번의 생명', interest:'게임 · 아케이드', title:'이번 생에는 재시작이 없습니다.', code:'THE SINGLE LIFE', message:'한 번의 생명. 아직 움직일 수 있는 시간이 남아있습니다.', action:'점프해 보기', hint:'실제 게임이 아닌 시안입니다. 점프해도 시간을 더하지 않습니다.', summary:'충전되지 않는 생명 게이지. 좋아하는 게임의 언어로 느끼는 유한함.', build:game,
    thumbnail:miniature('<rect x="34" y="24" width="132" height="19"/><path class="solid" d="M39 29h77v9H39Z"/><path d="M37 94h126M152 94V76h10v18"/><path class="solid" d="M80 60h12v12H80Zm-4 14h20v12H76Zm4 12h5v8h-5Zm10 0h5v8h-5Z"/>') },
];

scenes.forEach((scene,index) => {
  const tab=document.createElement('button'); tab.className='scene-tab'; tab.id=`scene-tab-${index}`;
  tab.setAttribute('role','tab'); tab.setAttribute('aria-controls','scene-panel');
  tab.innerHTML=`<small>0${index+1}</small><span>${scene.name}</span>`;
  tab.addEventListener('click',()=>selectScene(index));
  tab.addEventListener('keydown',event=>{
    let next;
    if(event.key==='ArrowRight') next=(selected+1)%scenes.length;
    if(event.key==='ArrowLeft') next=(selected+scenes.length-1)%scenes.length;
    if(event.key==='Home') next=0;
    if(event.key==='End') next=scenes.length-1;
    if(next===undefined) return;
    event.preventDefault(); selectScene(next); selector.children[next].focus();
  }); selector.append(tab);
  const entry=document.createElement('button'); entry.className='concept-entry';
  entry.innerHTML=`<span class="concept-art">${scene.thumbnail}</span><small>0${index+1} / ${scene.interest}</small><strong>${scene.object??scene.name}</strong><span>${scene.summary}</span>`;
  entry.addEventListener('click',()=>{
    selectScene(index); selector.children[index].focus({preventScroll:true});
    selector.scrollIntoView({behavior:motionAllowed()?'smooth':'instant',block:'start'});
  }); list.append(entry);
});

function cancelEffects(){ art.querySelectorAll('*').forEach(element=>element.getAnimations().forEach(animation=>animation.cancel())); }
function selectScene(index){
  cancelEffects(); selected=index; vinylPaused=false; vinylAngle=0; vinylUpdatedAt=0; bookmarkSet=false; treeFocused=false;
  const scene=scenes[index];
  [...selector.children].forEach((tab,i)=>{tab.setAttribute('aria-selected',String(i===index));tab.tabIndex=i===index?0:-1;});
  [...list.children].forEach((entry,i)=>entry.setAttribute('aria-pressed',String(i===index)));
  document.querySelector('#scene-panel').setAttribute('aria-labelledby',`scene-tab-${index}`);
  document.querySelector('#scene-code').textContent=`0${index+1} / ${scene.code}`;
  document.querySelector('#scene-category').textContent=`0${index+1} / ${scene.interest}`;
  document.querySelector('#scene-title').textContent=scene.title;
  message.textContent=scene.message; action.textContent=scene.action;
  action.removeAttribute('aria-pressed');
  if(index===1||index===2||index===3) action.setAttribute('aria-pressed','false');
  document.querySelector('#scene-hint').textContent=scene.hint;
  art.innerHTML=scene.build();
  refs=Object.fromEntries([...art.querySelectorAll('[data-ref]')].map(element=>[element.dataset.ref,element]));
  renderScene(motionAllowed()?(Date.now()-startedAt)/1000:2); updateClock(); scheduleMotion();
}
function effect(element,frames,options={}){
  if(!element||!motionAllowed()) return;
  element.getAnimations().forEach(animation=>animation.cancel());
  return element.animate(frames,{duration:420,easing:'cubic-bezier(.25,1,.5,1)',...options});
}
function renderScene(t){
  if(selected===0){
    const endY=304-95*Math.sqrt(1-remainingRatio()); const fall=(t%1)**1.6;
    refs.grain.setAttribute('transform',`translate(0 ${fall*(endY-192)})`); refs.grain.style.opacity=String(.9-.5*fall);
  }
  if(selected===1){
    if(vinylUpdatedAt&&!vinylPaused) vinylAngle=(vinylAngle+Math.min(.1,Math.max(0,t-vinylUpdatedAt))*24)%360;
    vinylUpdatedAt=t; refs.record.style.transform=`rotate(${vinylAngle}deg)`;
  }
  if(selected===2) refs.cursor.style.opacity=String(.65+Math.sin(t*Math.PI)*.25);
  if(selected===3) refs['growth-dot'].style.opacity=String(.8+Math.sin(t*1.8)*.2);
  if(selected===4){
    const step=Math.floor(t*2)%2;
    refs['game-leg-a'].setAttribute('transform',`translate(${step?1:0} ${step?-1:0})`);
    refs['game-leg-b'].setAttribute('transform',`translate(${step?-1:0} ${step?0:-1})`);
  }
}
function animateFrame(now){
  frame=null; if(document.hidden||!visible||!motionAllowed()) return;
  if(now-lastFrame>=1000/30){renderScene((Date.now()-startedAt)/1000);lastFrame=now;}
  frame=requestAnimationFrame(animateFrame);
}
function scheduleMotion(){
  cancelAnimationFrame(frame);frame=null;vinylUpdatedAt=0;
  if(!document.hidden&&visible&&motionAllowed()) frame=requestAnimationFrame(animateFrame);
}
function updateClock(){
  document.querySelector('#seconds').textContent=number.format(secondsNow());
  document.querySelector('#life-fraction').textContent=`남은 삶 ${(remainingRatio()*100).toFixed(1)}%\n예시 · 83년`;
}
action.addEventListener('click',()=>{
  if(selected===0){
    effect(refs.glass,[{transform:'rotate(0deg)'},{transform:'rotate(180deg)'}],{duration:460});
    message.textContent='뒤집어도, 지나간 초는 돌아오지 않습니다.';
  }
  if(selected===1){
    vinylPaused=!vinylPaused;action.textContent=vinylPaused?'다시 재생하기':'잠깐 멈춰 보기';action.setAttribute('aria-pressed',String(vinylPaused));
    refs['record-icon'].innerHTML=vinylPaused?'<path class="solid" d="M571 278l12 7-12 7Z"/>':'<path d="M571 278V292M582 278V292"/>';
    message.textContent=vinylPaused?'레코드는 멈췄지만, 당신의 시간은 계속 흐릅니다.':scenes[1].message;
  }
  if(selected===2){
    bookmarkSet=!bookmarkSet;refs.bookmark.style.opacity=bookmarkSet?'1':'0';action.textContent=bookmarkSet?'책갈피 빼기':'책갈피 꽂기';action.setAttribute('aria-pressed',String(bookmarkSet));
    effect(refs.bookmark,[{opacity:bookmarkSet?0:1,transform:`translateY(${bookmarkSet?-12:0}px)`},{opacity:bookmarkSet?1:0,transform:`translateY(${bookmarkSet?0:-8}px)`}],{duration:280});
    message.textContent=bookmarkSet?'지금 쓰고 있는 이 장에, 무엇을 남기고 싶나요?':scenes[2].message;
  }
  if(selected===3){
    treeFocused=!treeFocused; const scale=treeFocused?1.1:1;refs.tree.style.transform=`scale(${scale})`;action.textContent=treeFocused?'전체 나이테 보기':'나이테 자세히 보기';action.setAttribute('aria-pressed',String(treeFocused));
    effect(refs.tree,[{transform:`scale(${treeFocused?1:1.1})`},{transform:`scale(${scale})`}],{duration:320});
    message.textContent=treeFocused?`${livedYears().toFixed(1)}년의 경험이 당신 안에 남아있습니다.`:scenes[3].message;
  }
  if(selected===4){
    // A single physical jump, not bouncing UI. Life keeps decreasing throughout.
    effect(refs.runner,[{transform:'translateY(0)',offset:0},{transform:'translateY(-21px)',offset:.25},{transform:'translateY(-28px)',offset:.5},{transform:'translateY(-21px)',offset:.75},{transform:'translateY(0)',offset:1}],{duration:440,easing:'linear'});
    message.textContent='점프는 할 수 있어도, 지나간 초를 되돌릴 수는 없습니다.';
  }
});
function updateMotionPreference(){
  cancelEffects();document.body.classList.toggle('motion-reduced',!motionAllowed());
  if(!motionAllowed()) renderScene(2);scheduleMotion();
}
reduceControl.addEventListener('change',updateMotionPreference);
systemMotion.addEventListener('change',()=>{if(systemMotion.matches)reduceControl.checked=true;updateMotionPreference();});
document.querySelectorAll('[data-theme]').forEach(button=>button.addEventListener('click',()=>{
  stage.classList.toggle('light',button.dataset.theme==='light');document.querySelectorAll('[data-theme]').forEach(option=>option.setAttribute('aria-pressed',String(option===button)));
}));
const observer=new IntersectionObserver(entries=>{visible=entries[0].isIntersecting;scheduleMotion();});observer.observe(stage);
function resumeClock(){clearInterval(clock);updateClock();clock=setInterval(updateClock,250);}
document.addEventListener('visibilitychange',()=>{
  if(document.hidden){clearInterval(clock);cancelAnimationFrame(frame);cancelEffects();}else{resumeClock();scheduleMotion();}
});
window.addEventListener('pagehide',()=>{clearInterval(clock);cancelAnimationFrame(frame);observer.disconnect();cancelEffects();});
window.addEventListener('pageshow',event=>{if(event.persisted){observer.observe(stage);resumeClock();scheduleMotion();}});
selectScene(0);updateMotionPreference();resumeClock();
