// Native `<a href="#id">` anchors already move the browser's scroll
// position; this fills in the missing accessibility half of that
// navigation: moving keyboard focus to the destination too, so Tab
// continues from the section a user just jumped to (rather than wherever
// focus happened to be before) and so screen readers announce landing on
// the new landmark. This runs once, globally, for every in-page hash
// link - the topbar, the docs sidebar, the API index, the skip link, and
// the footer's "back to top" - instead of being duplicated per component.
//
// `focus({ preventScroll: true })` is what keeps this from causing the
// "second unwanted scroll" a naive `.focus()` would: the browser's own
// (possibly smooth-animated, see global.scss) scroll to the target stays
// in sole control of where the viewport ends up.

// The screenshot tool renders one isolated component at a time and never
// interacts with the page (see DocsNav.client.ts for the same guard), so
// skip all of this in that mode.
const screenshotName = new URLSearchParams(window.location.search).get('component');

function focusTarget(id: string): void {
  const target = document.getElementById(id);
  if (!target) {
    return;
  }
  // Sections, articles, and <main> aren't natively focusable; tabindex="-1"
  // makes them a valid .focus() target without adding them to the Tab
  // order (only tabindex >= 0 does that), so this is safe to leave in
  // place permanently.
  if (!target.hasAttribute('tabindex')) {
    target.setAttribute('tabindex', '-1');
  }
  target.focus({ preventScroll: true });
}

function focusFromHash(hash: string): void {
  if (!hash || hash === '#') {
    return;
  }
  focusTarget(decodeURIComponent(hash.slice(1)));
}

function setupAnchorFocus(): void {
  document.addEventListener('click', (event) => {
    const link = (event.target as HTMLElement).closest<HTMLAnchorElement>('a[href^="#"]');
    if (!link) {
      return;
    }
    const hash = link.getAttribute('href') || '';
    // Deferred a frame so the browser's own native scroll/hash update
    // (and, for the mobile drawer, DocsNav's close-on-select handler)
    // runs first - this only ever adds focus on top of it.
    requestAnimationFrame(() => focusFromHash(hash));
  });

  // Covers back/forward navigation, reloads with a hash already in the
  // URL bar, and hash URLs pasted while already on the page.
  window.addEventListener('hashchange', () => {
    focusFromHash(window.location.hash);
  });

  if (window.location.hash) {
    requestAnimationFrame(() => focusFromHash(window.location.hash));
  }
}

if (!screenshotName) {
  setupAnchorFocus();
}
