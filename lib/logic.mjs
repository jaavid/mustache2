/** Portable geometry and navigation; deterministic enough for Node tests. */
export const clamp = (n, a, b) => Math.min(b, Math.max(a, n));
export function faceHit(px, py, fx, fy, rx = 14, ry = 10) {
  return ((px - fx) / rx) ** 2 + ((py - fy) / ry) ** 2 <= 1;
}
export function circleRect(x, y, radius, rect) {
  const cx = clamp(x, rect.x, rect.x + rect.w);
  const cy = clamp(y, rect.y, rect.y + rect.h);
  return (x - cx) ** 2 + (y - cy) ** 2 < radius * radius;
}
export function blocked(x, y, radius, obstacles, bounds = { minX: 94, minY: 94, maxX: 1420, maxY: 924 }) {
  if (x - radius < bounds.minX || y - radius < bounds.minY || x + radius > bounds.maxX || y + radius > bounds.maxY) return true;
  return obstacles.some(r => circleRect(x, y, radius, r));
}
export function uniqueSpots(spots, count, random = Math.random) {
  const pool = spots.slice();
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool.slice(0, count);
}
export function gridPath(from, to, obstacles, cell = 34) {
  const cols = Math.ceil(1460 / cell), rows = Math.ceil(980 / cell);
  const index = (x, y) => y * cols + x;
  const point = id => ({ x: (id % cols + .5) * cell, y: (Math.floor(id / cols) + .5) * cell });
  const roundCell = p => [clamp(Math.floor(p.x / cell), 0, cols - 1), clamp(Math.floor(p.y / cell), 0, rows - 1)];
  const [sx, sy] = roundCell(from), [tx, ty] = roundCell(to);
  const start = index(sx, sy), end = index(tx, ty);
  const parent = new Int32Array(cols * rows).fill(-1);
  const queue = new Int32Array(cols * rows);
  let head = 0, tail = 0;
  parent[start] = start; queue[tail++] = start;
  const steps = [[1,0],[-1,0],[0,1],[0,-1]];
  while (head < tail) {
    const id = queue[head++]; if (id === end) break;
    const x = id % cols, y = Math.floor(id / cols);
    for (const [dx, dy] of steps) {
      const nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
      const next = index(nx, ny);
      if (parent[next] !== -1) continue;
      const p = point(next);
      if (blocked(p.x, p.y, 10, obstacles)) continue;
      parent[next] = id; queue[tail++] = next;
    }
  }
  if (parent[end] === -1) return [];
  const path = [];
  for (let node = end; node !== start; node = parent[node]) path.push(point(node));
  path.reverse();
  return path;
}
