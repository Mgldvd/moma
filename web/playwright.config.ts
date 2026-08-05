import { existsSync } from 'node:fs';
import { defineConfig, devices } from '@playwright/test';

const PORT = 4322;

// This sandbox has no network access for Playwright's own browser download,
// but a system Chromium is preinstalled - point at that instead of relying
// on `npx playwright install`. Machines with a normal internet connection
// can run that install and this falls through to Playwright's managed
// browser (executablePath: undefined) once no candidate path matches.
function systemChromiumPath(): string | undefined {
  if (process.env.PLAYWRIGHT_CHROMIUM_PATH) {
    return process.env.PLAYWRIGHT_CHROMIUM_PATH;
  }
  return ['/usr/bin/chromium', '/usr/bin/chromium-browser', '/usr/bin/google-chrome'].find(existsSync);
}

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: 'list',
  use: {
    baseURL: `http://localhost:${PORT}/moma/`,
    trace: 'on-first-retry',
  },
  // Builds the real static output and serves it via `astro preview`, so
  // these tests exercise the same artifact that ships to GitHub Pages
  // rather than the dev server's on-demand image pipeline.
  webServer: {
    command: `npm run build && npm run preview -- --port ${PORT}`,
    url: `http://localhost:${PORT}/moma/`,
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        launchOptions: { executablePath: systemChromiumPath() },
      },
    },
  ],
});
