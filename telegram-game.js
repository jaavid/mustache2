/** Official Telegram Games bridge (not a Mini App). Never submit scores outside Telegram sessions.
 * Backend scores are casual-only until authoritative replay is implemented.
 */
export const TELEGRAM_BOT_GAME_LINK = 'https://t.me/RJTtobot?game=mustache2';
const BASE = 'https://mustache.zedai.ir';
const TOKEN_FORMAT = /^[0-9a-f]{64}$/;

export function createTelegramGameBridge({ onStatus = () => {}, onLeaderboard = () => {}, fetcher = fetch, location = window.location }) {
  const token = new URLSearchParams(location.search).get('tg_session');
  const enabled = typeof token === 'string' && TOKEN_FORMAT.test(token);
  let currentRound = null;
  if (!enabled) return {
    enabled: false,
    startRound() {},
    async finishRound() {},
    async leaderboard() { return null; },
    shareScore() { return false; },
  };

  async function request(path, payload) {
    const response = await fetcher(BASE + '/api/mustache2/' + path, {
      method: payload === undefined ? 'GET' : 'POST',
      mode: 'cors',
      credentials: 'omit',
      cache: 'no-store',
      referrerPolicy: 'no-referrer',
      headers: { Authorization: 'Bearer ' + token, ...(payload === undefined ? {} : { 'Content-Type': 'application/json' }) },
      ...(payload === undefined ? {} : { body: JSON.stringify(payload) }),
    });
    if (!response.ok) throw new Error(response.status === 401 ? 'SESSION_EXPIRED' : 'API_UNAVAILABLE');
    return response.json();
  }

  return {
    enabled: true,
    startRound() {
      onStatus('در حال ثبت شروع بازی در تلگرام…');
      currentRound = request('round/start', {}).then(result => result.roundId).catch(() => {
        onStatus('اتصال به سرور امتیاز برقرار نشد؛ این دور فقط محلی است.');
        return null;
      });
    },
    async finishRound(result) {
      const started = currentRound;
      if (!started) return;
      currentRound = null;
      const roundId = await started;
      if (!roundId) return;
      onStatus('در حال ثبت رکورد در تلگرام…');
      try {
        const data = await request('round/finish', { roundId, ...result });
        onLeaderboard(data.leaderboard);
        onStatus('امتیاز ' + data.score + ' ثبت شد. وضعیت رکورد تلگرام: ' +
          (data.telegramState === 'updated' ? 'به‌روزرسانی شد' :
           data.telegramState === 'previous_best' ? 'رکورد قبلی بالاتر است' :
           'نیازمند تلاش مجدد برای همگام‌سازی') + '.');
      } catch (error) {
        onStatus(error?.message === 'SESSION_EXPIRED' ?
          'نشست تلگرام منقضی شد؛ بازی را از کارت تلگرام دوباره اجرا کن.' :
          'ثبت امتیاز انجام نشد؛ این دور فقط محلی است.');
      }
    },
    async leaderboard() {
      try {
        const result = await request('leaderboard');
        onLeaderboard(result);
        return result;
      } catch {
        onStatus('دریافت رتبه‌بندی فعلاً ممکن نیست.');
        return null;
      }
    },
    shareScore() {
      try {
        const proxy = window.TelegramGameProxy;
        if (typeof proxy?.shareScore === 'function') {
          proxy.shareScore();
          return true;
        }
        if (typeof navigator.share === 'function') {
          void navigator.share({ title: 'Mustache2', url: TELEGRAM_BOT_GAME_LINK }).catch(() => {});
          return true;
        }
        if (navigator.clipboard?.writeText) {
          void navigator.clipboard.writeText(TELEGRAM_BOT_GAME_LINK).catch(() => {});
          onStatus('لینک بازی برای اشتراک‌گذاری کپی شد.');
          return true;
        }
      } catch { /* unavailable on this device */ }
      return false;
    },
  };
}
