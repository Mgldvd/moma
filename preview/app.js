const root = document.documentElement;
const themeToggle = document.querySelector('.theme-toggle');
const searchInput = document.querySelector('.search__input');
const count = document.querySelector('.docs-index__count');
const entries = [...document.querySelectorAll('[data-api]')];
const groups = [...document.querySelectorAll('[data-group]')];
const emptyState = document.querySelector('.empty-state');

const savedTheme = localStorage.getItem('moma-preview-theme');
if (savedTheme === 'light' || savedTheme === 'dark') {
  root.dataset.theme = savedTheme;
}

function syncThemeButton() {
  const isDark = root.dataset.theme === 'dark';
  themeToggle.setAttribute('aria-pressed', String(isDark));
  themeToggle.setAttribute('aria-label', isDark ? 'Use light theme' : 'Use dark theme');
}

function filterComponents() {
  const query = searchInput.value.trim().toLowerCase();
  let visibleCount = 0;

  entries.forEach((entry) => {
    const isVisible = entry.dataset.api.includes(query);
    entry.hidden = !isVisible;
    visibleCount += Number(isVisible);
  });

  groups.forEach((group) => {
    group.hidden = !group.querySelector('[data-api]:not([hidden])');
  });

  count.textContent = String(visibleCount);
  emptyState.hidden = visibleCount !== 0;
}

themeToggle.addEventListener('click', () => {
  root.dataset.theme = root.dataset.theme === 'dark' ? 'light' : 'dark';
  localStorage.setItem('moma-preview-theme', root.dataset.theme);
  syncThemeButton();
});

searchInput.addEventListener('input', filterComponents);

document.addEventListener('keydown', (event) => {
  if (event.key === '/' && document.activeElement !== searchInput) {
    event.preventDefault();
    searchInput.focus();
  }
});

syncThemeButton();
count.textContent = String(entries.length);
