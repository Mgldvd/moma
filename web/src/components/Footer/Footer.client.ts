const root = document.documentElement;
const footer = document.querySelector<HTMLElement>('.footer');

if (footer) {
  const themeToggle = footer.querySelector<HTMLButtonElement>('.theme-toggle');

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

  syncThemeButton();
}
