import { highlightBashSyntax } from '../../utils/bashHighlight';
import { ENTRY_VISIBILITY_EVENT, FILTER_EVENT, type FilterDetail } from '../../utils/events';

// The screenshot tool (generate-screenshots.sh) loads this page with
// ?component=<id> to capture one isolated component at a time. See
// BaseLayout's bootstrap script for the matching page-level presentation
// mode, and src/styles/pages/index-screenshot.scss for its styles.
const screenshotName = new URLSearchParams(window.location.search).get('component');

document.querySelectorAll<HTMLElement>('.api-entry').forEach((entry) => {
  const id = entry.id;
  const searchText = entry.dataset.api || '';

  entry.querySelectorAll<HTMLElement>('.api-examples__code').forEach((code) => {
    code.innerHTML = highlightBashSyntax(code.textContent || '');
  });

  const signatureToggle = entry.querySelector<HTMLButtonElement>('.signature-toggle');
  const signatureOptions = entry.querySelector<HTMLElement>('.signature-options');
  if (signatureToggle && signatureOptions) {
    let collapseTimeout: number | undefined;
    // Same two-step reveal Lightbox.client.ts/DocsNav.client.ts use for
    // their own transitions: unhide *before* the animated attribute so the
    // panel has real content to grow into, then re-hide only once the
    // collapse transition has actually finished playing.
    signatureToggle.addEventListener('click', () => {
      const expanded = signatureToggle.getAttribute('aria-expanded') === 'true';
      signatureToggle.setAttribute('aria-expanded', String(!expanded));
      window.clearTimeout(collapseTimeout);
      if (expanded) {
        signatureOptions.dataset.open = 'false';
        collapseTimeout = window.setTimeout(() => {
          signatureOptions.hidden = true;
        }, 200);
      } else {
        signatureOptions.hidden = false;
        requestAnimationFrame(() => {
          signatureOptions.dataset.open = 'true';
        });
      }
    });
  }

  function setVisible(visible: boolean): void {
    entry.hidden = !visible;
    entry.dispatchEvent(
      new CustomEvent(ENTRY_VISIBILITY_EVENT, { bubbles: true, detail: { id, visible } }),
    );
  }

  if (screenshotName) {
    const isTarget = id === screenshotName;
    setVisible(isTarget);
    if (isTarget) {
      entry.classList.add('component-preview--screenshot-target');
    }
  } else {
    setVisible(true);
  }

  document.addEventListener(FILTER_EVENT, (event) => {
    if (screenshotName) {
      return;
    }
    const { query } = (event as CustomEvent<FilterDetail>).detail;
    setVisible(searchText.includes(query));
  });
});
