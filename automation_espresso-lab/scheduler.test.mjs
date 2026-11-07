import test from 'node:test';
import assert from 'node:assert/strict';
import { dailyPlan, dueByHour } from './scheduler.mjs';

test('daily plan is stable for a UTC day and schedules one to three unique hours', () => {
  const first = dailyPlan('2026-11-07');
  const second = dailyPlan('2026-11-07');
  assert.deepEqual(first, second);
  assert.ok(first.target >= 1 && first.target <= 3);
  assert.equal(first.hours.length, first.target);
  assert.equal(new Set(first.hours).size, first.target);
  assert.ok(first.hours.every((hour) => hour >= 0 && hour < 24));
});

test('due count increases only as scheduled UTC hours pass', () => {
  const plan = { target: 2, hours: [5, 19] };
  assert.equal(dueByHour(plan, 4), 0);
  assert.equal(dueByHour(plan, 5), 1);
  assert.equal(dueByHour(plan, 18), 1);
  assert.equal(dueByHour(plan, 19), 2);
});
