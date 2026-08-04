import { ENTRY_VISIBILITY_EVENT } from '../../utils/events';

// Listening on each section itself (rather than on `document`) relies on
// nothing but standard event bubbling from its own ApiEntry descendants,
// so this never has to query into ApiEntry's internals.
document.querySelectorAll<HTMLElement>('.api-section[data-filterable]').forEach((section) => {
  function recomputeVisibility(): void {
    section.hidden = !section.querySelector('.api-entry:not([hidden])');
  }

  section.addEventListener(ENTRY_VISIBILITY_EVENT, recomputeVisibility);
  recomputeVisibility();
});
