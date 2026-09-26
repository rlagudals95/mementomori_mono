export const DAY = 86_400_000;
export const YEAR = 365.2425 * DAY;
export const DEFAULT_YEARS = 83.7;
export const STORAGE_KEY = 'mementomori.v1';

// A date-only birthday is interpreted in the device's local time zone.
export function parseBirthday(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const [year, month, day] = value.split('-').map(Number);
  if (year < 1900 || year > 9999) return null;
  const date = new Date(year, month - 1, day);
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) return null;
  return date;
}

export function localDateKey(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function validateProfile(profile, now = Date.now()) {
  const birthday = parseBirthday(profile?.birthday);
  if (!birthday) return '올바른 생년월일을 입력해 주세요.';
  if (birthday.getTime() > now) return '생년월일은 오늘 또는 그 이전이어야 해요.';
  if (typeof profile.years !== 'number' || !Number.isFinite(profile.years) || profile.years < 1 || profile.years > 120) {
    return '기준 수명은 1세부터 120세 사이로 입력해 주세요.';
  }
  return '';
}

export function lifeSnapshot(profile, now = Date.now()) {
  const error = validateProfile(profile, now);
  if (error) throw new Error(error);
  const birth = parseBirthday(profile.birthday).getTime();
  const duration = profile.years * YEAR;
  const end = birth + duration;
  const elapsed = Math.max(0, now - birth);
  const remaining = Math.max(0, end - now);
  const seconds = Math.max(0, Math.ceil(remaining / 1000));
  return {
    birth, end, duration, elapsed, remaining, seconds, referenceYears: profile.years,
    days: Math.floor(seconds / 86400),
    hours: Math.floor(seconds / 3600) % 24,
    minutes: Math.floor(seconds / 60) % 60,
    second: seconds % 60,
    progress: Math.min(1, elapsed / duration),
    livedWeeks: Math.min(Math.floor(elapsed / (7 * DAY)), Math.ceil(duration / (7 * DAY))),
    totalWeeks: Math.ceil(duration / (7 * DAY)),
    passed: remaining === 0,
  };
}

export function readState(storage, now = Date.now()) {
  try {
    const data = JSON.parse(storage.getItem(STORAGE_KEY));
    if (!data || typeof data !== 'object') return {};
    const profile = !validateProfile(data.profile, now) ? {
      birthday: data.profile.birthday, years: data.profile.years,
    } : undefined;
    const intention = data.intention && typeof data.intention.text === 'string' &&
      typeof data.intention.date === 'string' ? {
        text: data.intention.text.slice(0, 100), date: data.intention.date,
      } : undefined;
    return { profile, intention, mode: data.mode === 'days' ? 'days' : 'seconds' };
  } catch { return {}; }
}
