import test from 'node:test';
import assert from 'node:assert/strict';
import { faceHit, circleRect, blocked, uniqueSpots, gridPath } from '../lib/logic.mjs';
test('a mustache only captures on the lip ellipse', () => {
  assert.equal(faceHit(100, 200, 100, 200), true);
  assert.equal(faceHit(114, 200, 100, 200), true);
  assert.equal(faceHit(100, 211, 100, 200), false);
  assert.equal(faceHit(130, 200, 100, 200), false);
});
test('walls and obstacles block circular characters', () => {
  const obstacle = { x: 120, y: 130, w: 90, h: 40 };
  assert.equal(circleRect(125, 140, 10, obstacle), true);
  assert.equal(circleRect(250, 250, 10, obstacle), false);
  assert.equal(blocked(125, 140, 12, [obstacle]), true);
  assert.equal(blocked(400, 400, 12, [obstacle]), false);
  assert.equal(blocked(82, 400, 12, []), true);
});
test('each character gets a unique hiding spot', () => {
  const spots = [{ x: 1 }, { x: 2 }, { x: 3 }, { x: 4 }, { x: 5 }];
  const selected = uniqueSpots(spots, 3, () => 0.1);
  assert.equal(selected.length, 3);
  assert.equal(new Set(selected.map(s => s.x)).size, 3);
  assert.deepEqual(spots.map(s => s.x), [1,2,3,4,5]);
});
test('grid navigation finds a path around an obstacle', () => {
  const obstacle = { x: 320, y: 330, w: 110, h: 110 };
  const route = gridPath({ x: 235, y: 385 }, { x: 550, y: 385 }, [obstacle]);
  assert.ok(route.length > 0);
  assert.ok(route.every(p => !blocked(p.x,p.y,10,[obstacle])));
  assert.ok(route.some(p => p.y < 315 || p.y > 455));
});
test('grid navigation handles unreachable goals without hanging', () => {
  const wall = { x: 270, y: 90, w: 30, h: 860 };
  const route = gridPath({ x: 190, y: 190 }, { x: 420, y: 190 }, [wall]);
  assert.deepEqual(route, []);
});