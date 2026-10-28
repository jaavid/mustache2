import test from 'node:test';
import assert from 'node:assert/strict';
import { createTelegramGameBridge, TELEGRAM_BOT_GAME_LINK } from '../telegram-game.js';

test('standalone visitors never call the score API', async () => {
  let requests = 0;
  const bridge = createTelegramGameBridge({
    location: { search: '' },
    fetcher: async () => { requests++; throw Error('Must not call API'); },
  });
  bridge.startRound();
  await bridge.finishRound({ score: 1000, caught: 1, shots: 3, elapsedSeconds: 180 });
  assert.equal(bridge.enabled, false);
  assert.equal(requests, 0);
  assert.match(TELEGRAM_BOT_GAME_LINK, /game=mustache2/);
});

test('only valid Telegram sessions submit start/finish and fetch leaderboards', async () => {
  const token = 'a'.repeat(64);
  const calls = [];
  const bridge = createTelegramGameBridge({
    location: { search: '?tg_session=' + token },
    fetcher: async (url, options) => {
      calls.push({ url, options });
      if (url.endsWith('/round/start')) return Response.json({ roundId: '9b9a4b33-149c-4673-80de-35d07cda3f6b' });
      if (url.endsWith('/round/finish')) return Response.json({ score: 1000, telegramState: 'updated', leaderboard: { top: [] } });
      return Response.json({ top: [], players: 1 });
    },
  });
  bridge.startRound();
  await bridge.finishRound({ score: 1000, caught: 1, shots: 2, elapsedSeconds: 180 });
  await bridge.leaderboard();
  assert.equal(calls.length, 3);
  assert.deepEqual(calls.map(x => new URL(x.url).pathname), [
    '/api/mustache2/round/start', '/api/mustache2/round/finish', '/api/mustache2/leaderboard',
  ]);
  assert.equal(JSON.parse(calls[1].options.body).caught, 1);
  for (const call of calls) {
    assert.equal(call.options.headers.Authorization, 'Bearer ' + token);
    assert.equal(call.options.credentials, 'omit');
    assert.equal(call.options.referrerPolicy, 'no-referrer');
  }
});

test('invalid session tokens do not send network requests', async () => {
  let requests = 0;
  const bridge = createTelegramGameBridge({
    location: { search: '?tg_session=invalid' },
    fetcher: async () => { requests++; throw Error('Must not call'); },
  });
  bridge.startRound();
  await bridge.finishRound({ score: 2 });
  assert.equal(bridge.enabled, false);
  assert.equal(requests, 0);
});
