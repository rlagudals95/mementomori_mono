import { validateProfile, parseBirthday } from './life.js';

export function validateSettingsFile(value, now = Date.now()) {
  if (value?.app !== 'mementomori' || value?.version !== 1) throw new Error('메멘토모리 설정 파일이 아니거나 지원하지 않는 버전입니다.');
  const state = value.state;
  if (!state || !['seconds', 'days'].includes(state.mode)) throw new Error('표시 단위를 확인해 주세요.');
  if (state.profile != null) {
    const error = validateProfile(state.profile, now);
    if (error) throw new Error(error);
  }
  if (state.intention != null && (typeof state.intention.text !== 'string' || state.intention.text.length > 100 || !parseBirthday(state.intention.date))) {
    throw new Error('오늘의 문장 형식이 올바르지 않습니다.');
  }
  if (!['wide', 'square', 'slim'].includes(value.widget?.variant) || !['dark', 'light'].includes(value.widget?.theme)) {
    throw new Error('위젯 디자인 설정을 확인해 주세요.');
  }
  return {
    app: 'mementomori', version: 1,
    state: {
      ...(state.profile ? { profile: { birthday: state.profile.birthday, years: state.profile.years } } : {}),
      ...(state.intention ? { intention: { text: state.intention.text, date: state.intention.date } } : {}),
      mode: state.mode,
    },
    widget: { variant: value.widget.variant, theme: value.widget.theme },
  };
}

export function parseSettingsFile(text, now = Date.now()) {
  if (new TextEncoder().encode(text).length > 65536) throw new Error('설정 파일은 64KB 이하여야 합니다.');
  let value;
  try { value = JSON.parse(text); } catch { throw new Error('설정 파일을 읽을 수 없습니다. 메멘토모리에서 내보낸 JSON 파일을 선택해 주세요.'); }
  return validateSettingsFile(value, now);
}

export function exportSettingsFile(state, widget) {
  return JSON.stringify(validateSettingsFile({ app: 'mementomori', version: 1, state: { ...state, mode: state.mode || 'seconds' }, widget }), null, 2);
}

// Preserve the previous settings if either storage write fails.
export function storeSettingsFile(storage, settings, stateKey, widgetKey) {
  if (!storage) throw new Error('이 브라우저에 설정을 저장할 수 없습니다.');
  const previousState = storage.getItem(stateKey);
  const previousWidget = storage.getItem(widgetKey);
  try {
    storage.setItem(stateKey, JSON.stringify(settings.state));
    storage.setItem(widgetKey, JSON.stringify(settings.widget));
  } catch {
    try {
      if (previousState === null) storage.removeItem(stateKey); else storage.setItem(stateKey, previousState);
      if (previousWidget === null) storage.removeItem(widgetKey); else storage.setItem(widgetKey, previousWidget);
    } catch { /* Storage may have become unavailable entirely. */ }
    throw new Error('설정을 저장하지 못했어요. 브라우저의 저장 공간을 확인해 주세요.');
  }
}
