import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { exportSettingsFile, parseSettingsFile, storeSettingsFile } from '../src/settings-transfer.js';
const example = JSON.parse(readFileSync(new URL('../../../shared/contracts/settings-example.json', import.meta.url)));
test('Mac and web settings format round trips without losing profile, intention or design', () => {
  assert.deepEqual(parseSettingsFile(exportSettingsFile(example.state, example.widget)), example);
  assert.equal(parseSettingsFile(exportSettingsFile({}, example.widget)).state.mode, 'seconds');
});
test('reject corrupt, future versions, invalid profile, dates, shapes and oversized files', () => {
  for (const mutate of [v => v.version = 2, v => v.state.profile.years = -1, v => v.state.profile.birthday = '2001-02-29', v => v.widget.variant = '__proto__', v => v.state.intention.text = 'a'.repeat(101), v => v.state.intention.date = '2026-02-30']) {
    const value = structuredClone(example); mutate(value);
    assert.throws(() => parseSettingsFile(JSON.stringify(value)));
  }
  assert.throws(() => parseSettingsFile('{broken'));
  assert.throws(() => parseSettingsFile(' '.repeat(65537)));
});
test('failed second storage write restores existing settings', () => {
  const items = new Map([['state', 'original state'], ['widget', 'original widget']]);
  let writes = 0;
  const storage = { getItem: key => items.get(key) ?? null, setItem: (key, value) => { if (++writes === 2) throw new Error('quota'); items.set(key, value); }, removeItem: key => items.delete(key) };
  assert.throws(() => storeSettingsFile(storage, example, 'state', 'widget'));
  assert.equal(items.get('state'), 'original state');
  assert.equal(items.get('widget'), 'original widget');
});

test('web conforms to shared timezone and countdown fixtures', async () => {
  const { lifeSnapshot } = await import('../src/life.js');
  const cases = JSON.parse(readFileSync(new URL('../../../shared/fixtures/life-cases.json', import.meta.url)));
  const previous = process.env.TZ;
  try {
    for (const fixture of cases) {
      process.env.TZ = fixture.timezone;
      const value = lifeSnapshot(fixture.profile, Date.parse(fixture.now));
      assert.equal(value.seconds, fixture.seconds);
      assert.equal(value.days, fixture.days);
      assert.ok(Math.abs(value.progress - fixture.progress) < 1e-10);
    }
  } finally { if (previous === undefined) delete process.env.TZ; else process.env.TZ = previous; }
});
