import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DAY, YEAR, parseBirthday, validateProfile, lifeSnapshot, readState, localDateKey } from '../src/life.js';

const profile = { birthday: '2000-01-01', years: 83.7 };
const birth = new Date(2000, 0, 1).getTime();

test('calendar dates reject overflow and accept leap days', () => {
  assert.equal(parseBirthday('2001-02-29'), null);
  assert.equal(parseBirthday('2000-13-01'), null);
  assert.equal(parseBirthday('2000-04-31'), null);
  assert.ok(parseBirthday('2000-02-29'));
});
test('future dates, non-numeric and unreasonable lifespans are rejected', () => {
  assert.ok(validateProfile({ ...profile, birthday: '2090-01-01' }, birth));
  for (const years of [NaN, Infinity, 0, 121, '83.7']) assert.ok(validateProfile({ ...profile, years }, birth));
  assert.equal(validateProfile(profile, birth), '');
});
test('countdown derives from the clock and catches up after background suspension', () => {
  const initial = lifeSnapshot(profile, birth + 30 * YEAR);
  const later = lifeSnapshot(profile, birth + 30 * YEAR + 3 * DAY + 1000);
  assert.equal(initial.seconds - later.seconds, 3 * 86400 + 1);
  assert.equal(initial.end, later.end);
  assert.ok(Math.abs(initial.progress - 30 / 83.7) < 1e-10);
});
test('seconds are decomposed consistently', () => {
  const end = birth + profile.years * YEAR;
  const snapshot = lifeSnapshot(profile, end - (2 * 86400 + 3661) * 1000);
  assert.deepEqual([snapshot.days, snapshot.hours, snapshot.minutes, snapshot.second], [2, 1, 1, 1]);
});
test('outliving the reference never creates a negative countdown or progress > 100%', () => {
  const snapshot = lifeSnapshot(profile, birth + 100 * YEAR);
  assert.equal(snapshot.seconds, 0);
  assert.equal(snapshot.passed, true);
  assert.equal(snapshot.progress, 1);
  assert.equal(snapshot.livedWeeks, snapshot.totalWeeks);
});
test('storage corruption or unavailable storage is recoverable', () => {
  assert.deepEqual(readState({ getItem: () => '{broken' }), {});
  assert.deepEqual(readState({ getItem: () => { throw new Error('blocked'); } }), {});
  assert.equal(readState({ getItem: () => JSON.stringify({ profile: { birthday: 'hello', years: -1 } }) }).profile, undefined);
});
test('only supported fields are restored, and intention length is bounded', () => {
  const state = readState({ getItem: () => JSON.stringify({ profile, mode: 'days', intention: { text: 'a'.repeat(200), date: '2026-09-26' }, extra: 'ignored' }) });
  assert.deepEqual(state.profile, profile);
  assert.equal(state.intention.text.length, 100);
  assert.equal(state.mode, 'days');
  assert.equal(state.extra, undefined);
});
test('local day keys use device calendar days', () => {
  assert.equal(localDateKey(new Date(2026, 8, 26, 23, 59)), '2026-09-26');
});
