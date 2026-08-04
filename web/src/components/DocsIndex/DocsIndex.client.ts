import {
  ENTRY_VISIBILITY_EVENT,
  FILTER_EVENT,
  type EntryVisibilityDetail,
} from '../../utils/events';

const docsIndex = document.querySelector<HTMLElement>('.docs-index');
const searchInput = docsIndex?.querySelector<HTMLInputElement>('.search__input');
const countEl = docsIndex?.querySelector<HTMLElement>('.docs-index__count');

if (docsIndex && searchInput && countEl) {
  const visibility = new Map<string, boolean>();

  searchInput.addEventListener('input', () => {
    const query = searchInput.value.trim().toLowerCase();
    document.dispatchEvent(new CustomEvent(FILTER_EVENT, { detail: { query } }));
  });

  document.addEventListener(ENTRY_VISIBILITY_EVENT, (event) => {
    const { id, visible } = (event as CustomEvent<EntryVisibilityDetail>).detail;
    visibility.set(id, visible);
    const visibleCount = [...visibility.values()].filter(Boolean).length;
    countEl.textContent = String(visibleCount);
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === '/' && document.activeElement !== searchInput) {
      event.preventDefault();
      searchInput.focus();
    }
  });
}
