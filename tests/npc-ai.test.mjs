import test from 'node:test';
import assert from 'node:assert/strict';
import { blocked } from '../lib/logic.mjs';
import {
  PERSONALITY, chooseCoverRoute, chooseFlankRoute,
  chooseNoiseSpot, canRehide, distance,
} from '../lib/npc-ai.mjs';

test('all three NPCs have independent personality policies', () => {
  assert.deepEqual(PERSONALITY, {
    ramin: 'cover',
    borhan: 'flank',
    mammad: 'decoy',
  });
});

test('Ramin prioritizes reachable table cover and path avoids obstacles', () => {
  const actor = { x: 650, y: 600, behavior: PERSONALITY.ramin };
  const player = { x: 600, y: 540 };
  const spots = [
    { x: 1300, y: 700, cover: 'sofa' },
    { x: 1200, y: 650, cover: 'table' },
  ];
  // Both sites must survive the safety filter; absent Ramin's cover bonus,
  // the more distant sofa is the preferred escape destination.
  assert.ok(spots.every(spot => distance(player, spot) > 180));
  const neutral = chooseCoverRoute({ ...actor, behavior: 'decoy' },
    player, spots, [], () => 0);
  assert.equal(neutral?.target.cover, 'sofa');
  const route = chooseCoverRoute(actor, player, spots, [], () => 0);
  assert.ok(route);
  assert.equal(route.target.cover, 'table');
  assert.ok(route.path.length);
  assert.ok(route.path.every(point => !blocked(point.x, point.y, 10, [])));
});

test('NPCs cannot choose a hiding spot inside an obstacle', () => {
  const actor = { x: 600, y: 650, behavior: PERSONALITY.ramin };
  const player = { x: 500, y: 500 };
  const obstacles = [{ x: 1000, y: 600, w: 120, h: 100 }];
  const spots = [
    { x: 1060, y: 650, cover: 'table' },
    { x: 300, y: 650, cover: 'sofa' },
  ];
  const route = chooseCoverRoute(actor, player, spots, obstacles, () => 0);
  assert.equal(route?.target.cover, 'sofa');
});

test('Borhan selects a real flank arc rather than simply fleeing in a line', () => {
  const player = { x: 350, y: 450 };
  const actor = { x: 590, y: 450, orbitDirection: 1 };
  const route = chooseFlankRoute(actor, player, []);
  assert.ok(route);
  assert.ok(route.path.length);
  assert.ok(Math.abs(route.target.y - player.y) > 90);
  assert.ok(distance(route.target, player) >= 270);
  assert.ok(route.path.every(point => !blocked(point.x, point.y, 10, [])));
});

test('Borhan uses alternate arc when one side is blocked', () => {
  const player = { x: 700, y: 490 };
  const actor = { x: 900, y: 490, orbitDirection: 1 };
  const obstacles = [{ x: 720, y: 530, w: 290, h: 250 }];
  const route = chooseFlankRoute(actor, player, obstacles);
  assert.ok(route);
  assert.ok(!blocked(route.target.x, route.target.y, 15, obstacles));
  assert.ok(route.path.every(point => !blocked(point.x, point.y, 10, obstacles)));
});

test('Mammad places false clues away from himself and other hidden characters', () => {
  const actor = { x: 1100, y: 700, behavior: PERSONALITY.mammad };
  const player = { x: 520, y: 500 };
  const hidden = [{ x: 460, y: 400 }];
  const unsafe = { x: 470, y: 400, name: 'actual hidden NPC' };
  const valid = { x: 680, y: 550, name: 'false clue' };
  const tooClose = { x: 1110, y: 710 };
  const selected = chooseNoiseSpot(actor, player, [unsafe, valid, tooClose], hidden, () => 0);
  assert.equal(selected, valid);
  actor.lastNoiseSpot = valid;
  assert.equal(chooseNoiseSpot(actor, player, [valid], [], () => 0), null);
});

test('Mammad cannot leave a decoy beside himself or the player', () => {
  const actor = { x: 400, y: 400 };
  const player = { x: 600, y: 600 };
  assert.equal(chooseNoiseSpot(actor, player, [
    { x: 410, y: 410 },
    { x: 605, y: 600 },
  ], [], () => 0), null);
});

test('rehiding requires reaching cover, chase time and separation', () => {
  const actor = { behavior: 'cover', x: 680, y: 700,
    target: { x: 684, y: 705 }, chaseTime: 3 };
  assert.equal(canRehide(actor, { x: 250, y: 250 }), true);
  assert.equal(canRehide(actor, { x: 550, y: 700 }), false);
  assert.equal(canRehide({ ...actor, chaseTime: 0.5 }, { x: 250, y: 250 }), false);
  assert.equal(canRehide({ ...actor, x: 600 }, { x: 250, y: 250 }), false);
  assert.equal(canRehide({ ...actor, target: null }, { x: 250, y: 250 }), false);
  assert.equal(canRehide({ ...actor, behavior: 'flank', chaseTime: 6 },
    { x: 250, y: 250 }), false);
  assert.equal(canRehide({ ...actor, behavior: 'flank', chaseTime: 8 },
    { x: 250, y: 250 }), true);
});
