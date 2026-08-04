import { NAV_TOGGLE_REQUEST, NAV_TOGGLE_STATE, type NavToggleStateDetail } from '../../utils/events';

const root = document.documentElement;
const header = document.querySelector<HTMLElement>('.topbar');
if (header) {
  const themeToggle = header.querySelector<HTMLButtonElement>('.theme-toggle');
  const navToggle = header.querySelector<HTMLButtonElement>('.nav-toggle');

  function syncThemeButton(): void {
    if (!themeToggle) {
      return;
    }
    const isDark = root.dataset.theme === 'dark';
    themeToggle.setAttribute('aria-pressed', String(isDark));
    themeToggle.setAttribute('aria-label', isDark ? 'Use light theme' : 'Use dark theme');
  }

  themeToggle?.addEventListener('click', () => {
    root.dataset.theme = root.dataset.theme === 'dark' ? 'light' : 'dark';
    localStorage.setItem('moma-preview-theme', root.dataset.theme);
    syncThemeButton();
  });

  navToggle?.addEventListener('click', () => {
    document.dispatchEvent(new CustomEvent(NAV_TOGGLE_REQUEST));
  });

  document.addEventListener(NAV_TOGGLE_STATE, (event) => {
    const { open } = (event as CustomEvent<NavToggleStateDetail>).detail;
    navToggle?.setAttribute('aria-expanded', String(open));
  });

  syncThemeButton();
}
