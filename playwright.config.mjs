import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests',
  testMatch: 'browser.spec.mjs',
  timeout: 30_000,
  use: { baseURL: 'http://127.0.0.1:5173', headless: true, viewport: { width: 1280, height: 800 } },
  webServer: {
    command: 'python3 -m http.server 5173 --bind 127.0.0.1 --directory dist',
    url: 'http://127.0.0.1:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 15_000
  }
});
