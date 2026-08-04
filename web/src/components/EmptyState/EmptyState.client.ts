import { ENTRY_VISIBILITY_EVENT, type EntryVisibilityDetail } from '../../utils/events';

const emptyState = document.querySelector<HTMLElement>('.empty-state');

if (emptyState) {
  const visibility = new Map<string, boolean>();

  document.addEventListener(ENTRY_VISIBILITY_EVENT, (event) => {
    const { id, visible } = (event as CustomEvent<EntryVisibilityDetail>).detail;
    visibility.set(id, visible);
    const hasVisible = [...visibility.values()].some(Boolean);
    emptyState.hidden = visibility.size === 0 || hasVisible;
  });
}
