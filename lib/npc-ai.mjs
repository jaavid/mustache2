/**
 * Small, deterministic personality policies for the Mustache2 NPCs.
 * Geometry/pathfinding stay in logic.mjs; policies don't access the DOM.
 */
import { blocked, gridPath } from './logic.mjs';

export const PERSONALITY = Object.freeze({
  ramin: 'cover',
  borhan: 'flank',
  mammad: 'decoy',
});

/** Compute Euclidean distance between two world-space positions. */
export const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);

/** Reject obstructed destinations and return only a traversable grid path. */
function routeTo(actor, target, obstacles) {
  if (blocked(target.x, target.y, 15, obstacles)) return null;
  const path = gridPath(actor, target, obstacles);
  return path.length ? { target, path } : null;
}

/**
 * Return a reachable hiding destination. Ramin heavily favors table edges;
 * the other characters prefer distance from the hunter over cover type.
 */
export function chooseCoverRoute(actor, player, spots, obstacles, random = Math.random) {
  const ranked = spots
    .filter(s => distance(actor, s) > 95 && distance(player, s) > 180)
    .map(s => ({
      spot: s,
      value: distance(player, s) - distance(actor, s) * .21 +
        (actor.behavior === 'cover' && s.cover === 'table' ? 330 : 0) +
        (actor.behavior === 'cover' && s.cover === 'sofa' ? 110 : 0) +
        random() * 28,
    }))
    .sort((a, b) => b.value - a.value);
  for (const entry of ranked) {
    const route = routeTo(actor, entry.spot, obstacles);
    if (route) return route;
  }
  return null;
}

/**
 * Borhan heads toward a tangential waypoint around the player instead of
 * running directly away. Candidate directions are collision/path checked.
 */
export function chooseFlankRoute(actor, player, obstacles) {
  const bearing = Math.atan2(actor.y - player.y, actor.x - player.x);
  const direction = actor.orbitDirection === -1 ? -1 : 1;
  for (const side of [direction, -direction]) {
    for (const offset of [1.12, 1.72, 2.25]) {
      for (const radius of [275, 335]) {
        const angle = bearing + offset * side;
        const target = {
          x: player.x + Math.cos(angle) * radius,
          y: player.y + Math.sin(angle) * radius,
        };
        if (distance(actor, target) < 85) continue;
        const route = routeTo(actor, target, obstacles);
        if (route) return { ...route, orbitDirection: side };
      }
    }
  }
  return null;
}

/**
 * Choose a visible false sound clue away from the actual Mammad and from
 * other hidden NPCs. Prefer a clue the player can reasonably investigate.
 */
export function chooseNoiseSpot(actor, player, spots, otherHidden = [], random = Math.random) {
  const pool = spots.filter(s =>
    distance(s, actor) > 210 &&
    distance(s, player) > 100 && distance(s, player) < 750 &&
    !otherHidden.some(other => distance(other, s) < 95) &&
    s !== actor.lastNoiseSpot
  );
  if (!pool.length) return null;
  return pool
    .map(spot => ({
      spot,
      value: 750 - distance(spot, player) + random() * 180,
    }))
    .sort((a, b) => b.value - a.value)[0].spot;
}

/** A fleeing actor can hide only after reaching cover safely. No teleporting. */
export function canRehide(actor, player) {
  if (!actor.target || distance(actor, actor.target) > 34) return false;
  const minTime = actor.behavior === 'flank' ? 7 : 1.7;
  const safeDistance = actor.behavior === 'flank' ? 390 : 300;
  return actor.chaseTime >= minTime && distance(actor, player) > safeDistance;
}
