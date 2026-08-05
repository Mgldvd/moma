import {
  ENTRY_VISIBILITY_EVENT,
  FILTER_EVENT,
  NAV_TOGGLE_REQUEST,
  NAV_TOGGLE_STATE,
  type EntryVisibilityDetail,
} from '../../utils/events';

const docsNav = document.querySelector<HTMLElement>('.docs-nav');
const docsNavBackdrop = document.querySelector<HTMLElement>('.docs-nav-backdrop');
const docsNavClose = docsNav?.querySelector<HTMLButtonElement>('.docs-nav__close');
const navLinks = [...document.querySelectorAll<HTMLAnchorElement>('.docs-nav__link')];
const navGroupEls = [...document.querySelectorAll<HTMLElement>('.docs-nav__group')];

// The screenshot tool renders one isolated component at a time and never
// interacts with the page, so the mobile drawer, scroll-spy, and search -
// all of which assume a normal viewport and user input - stay off in that
// mode.
const screenshotName = new URLSearchParams(window.location.search).get('component');

function setupMobileNav(): void {
  if (!docsNav || !docsNavBackdrop) {
    return;
  }

  const isNarrowViewport = () => window.matchMedia('(max-width: 959.98px)').matches;
  let lastFocused: HTMLElement | null = null;

  function focusableElements(): HTMLElement[] {
    return [...docsNav!.querySelectorAll<HTMLElement>('a[href], button:not([disabled])')]
      .filter((element) => element.offsetParent !== null);
  }

  function onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.preventDefault();
      closeNav();
      return;
    }
    if (event.key !== 'Tab') {
      return;
    }
    const focusables = focusableElements();
    if (focusables.length === 0) {
      return;
    }
    const first = focusables[0];
    const last = focusables[focusables.length - 1];
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  }

  function openNav(): void {
    lastFocused = document.activeElement as HTMLElement | null;
    docsNavBackdrop!.hidden = false;
    // The same <nav> is a persistent landmark on desktop; only present it
    // as a modal dialog while it behaves like one, on mobile.
    docsNav!.setAttribute('role', 'dialog');
    docsNav!.setAttribute('aria-modal', 'true');
    document.body.style.overflow = 'hidden';
    requestAnimationFrame(() => {
      docsNav!.dataset.open = 'true';
      docsNavBackdrop!.dataset.open = 'true';
    });
    const focusables = focusableElements();
    (focusables[0] || docsNav!).focus();
    document.addEventListener('keydown', onKeydown);
    document.dispatchEvent(new CustomEvent(NAV_TOGGLE_STATE, { detail: { open: true } }));
  }

  function closeNav({ restoreFocus = true } = {}): void {
    docsNav!.dataset.open = 'false';
    docsNavBackdrop!.dataset.open = 'false';
    docsNav!.removeAttribute('role');
    docsNav!.removeAttribute('aria-modal');
    document.body.style.overflow = '';
    document.removeEventListener('keydown', onKeydown);
    window.setTimeout(() => {
      if (docsNav!.dataset.open === 'false') {
        docsNavBackdrop!.hidden = true;
      }
    }, 220);
    if (restoreFocus && lastFocused) {
      lastFocused.focus();
    }
    document.dispatchEvent(new CustomEvent(NAV_TOGGLE_STATE, { detail: { open: false } }));
  }

  function isOpen(): boolean {
    return docsNav!.dataset.open === 'true';
  }

  document.addEventListener(NAV_TOGGLE_REQUEST, () => {
    if (isOpen()) {
      closeNav();
    } else {
      openNav();
    }
  });

  docsNavClose?.addEventListener('click', () => closeNav());
  docsNavBackdrop.addEventListener('click', () => closeNav());

  docsNav.addEventListener('click', (event) => {
    const target = event.target as HTMLElement;
    if (target.closest('a.docs-nav__link') && isOpen() && isNarrowViewport()) {
      closeNav({ restoreFocus: false });
    }
  });

  window.addEventListener('resize', () => {
    if (isOpen() && !isNarrowViewport()) {
      closeNav({ restoreFocus: false });
    }
  });
}

// Scroll-spy: highlight the sidebar link for the component or section
// currently in view, without ever touching browser history during scroll.
function setupScrollSpy(): void {
  if (navLinks.length === 0 || !docsNav) {
    return;
  }

  const linkByTargetId = new Map<string, HTMLAnchorElement>();
  const targets: HTMLElement[] = [];

  navLinks.forEach((link) => {
    const targetId = link.getAttribute('href')!.slice(1);
    const target = document.getElementById(targetId);
    if (target) {
      linkByTargetId.set(targetId, link);
      targets.push(target);
    }
  });

  let activeId = '';

  // While true, scroll-driven updates are ignored: a click (or hashchange)
  // to a far-away section can take the browser's smooth-scroll a while to
  // arrive, and during that time sections it passes through would otherwise
  // flash across the sidebar one after another before landing on the real
  // destination. Locking activeId to the clicked target for the duration of
  // that scroll - and only resuming live tracking once it actually settles
  // - keeps the highlight jumping straight to what the user asked for.
  let settling = false;
  let settleTimeout: number | undefined;
  let pendingTargetId: string | null = null;

  // On narrow viewports the sidebar is an off-canvas drawer: even while
  // closed it stays in the DOM (translated out of view), so scrollIntoView
  // on one of its links has no visible target to reveal and instead drags
  // the whole page's scroll position around. Only sync the sidebar's own
  // scroll position when that sidebar is actually on screen.
  function isNavOnScreen(): boolean {
    return window.matchMedia('(min-width: 960px)').matches || docsNav!.dataset.open === 'true';
  }

  // Whenever the sidebar's own list fits without overflowing (the common
  // desktop case), every link is already inside its scrollable ancestor's
  // viewport, so scrollIntoView "escapes" to the next real scrollable
  // ancestor - the window - and drags the whole page back to wherever that
  // link sits. Scrolling docsNav.scrollTop directly keeps this contained to
  // the sidebar no matter what does or doesn't overflow.
  function scrollLinkIntoNavView(link: HTMLAnchorElement): void {
    const navRect = docsNav!.getBoundingClientRect();
    const linkRect = link.getBoundingClientRect();
    if (linkRect.top < navRect.top) {
      docsNav!.scrollTop -= navRect.top - linkRect.top;
    } else if (linkRect.bottom > navRect.bottom) {
      docsNav!.scrollTop += linkRect.bottom - navRect.bottom;
    }
  }

  // scrollNavIntoView defaults to true so clicks, history navigation, and
  // scroll-driven updates keep the sidebar's own view in sync. It is
  // explicitly disabled for the very first activation on page load so this
  // never fights the browser's native scroll to a deep-linked anchor.
  function setActive(id: string, { scrollNavIntoView = true } = {}): void {
    if (id === activeId) {
      return;
    }
    activeId = id;
    navLinks.forEach((link) => {
      const isActive = link.getAttribute('href') === `#${id}`;
      if (isActive) {
        link.setAttribute('aria-current', 'location');
      } else {
        link.removeAttribute('aria-current');
      }
    });
    if (scrollNavIntoView && isNavOnScreen()) {
      const link = linkByTargetId.get(id);
      if (link) {
        scrollLinkIntoNavView(link);
      }
    }
  }

  function visibleTargetIds(): string[] {
    return targets.filter((target) => !target.hidden).map((target) => target.id);
  }

  function activateFromHash(options?: { scrollNavIntoView?: boolean }): boolean {
    const hashId = window.location.hash.slice(1);
    if (hashId && linkByTargetId.has(hashId)) {
      setActive(hashId, options);
      return true;
    }
    return false;
  }

  // Picks whichever candidate's top is closest to, but still above, the
  // threshold line below the sticky header - i.e. the section that most
  // recently scrolled into place. Candidates whose top has scrolled further
  // up the page (more negative) are further past the threshold, not nearer
  // to it, so they must lose to a candidate with a larger top even though
  // "larger top" reads like "lower on screen."
  function pickNearestAboveThreshold(
    candidates: { id: string; top: number }[],
    threshold: number,
  ): string {
    let candidate = '';
    let candidateTop = -Infinity;
    for (const { id, top } of candidates) {
      if (top <= threshold && top > candidateTop) {
        candidate = id;
        candidateTop = top;
      }
    }
    return candidate;
  }

  // Sidebar link order (grouped by category) does not match page scroll
  // order, so this scans every visible target rather than assuming an
  // already-sorted list.
  function activateTopmostVisible(options?: { scrollNavIntoView?: boolean }): void {
    const headerOffset = document.querySelector('.topbar')?.clientHeight ?? 0;
    const threshold = headerOffset + 24;
    const candidates = visibleTargetIds().map((id) => ({
      id,
      top: document.getElementById(id)!.getBoundingClientRect().top,
    }));
    const candidate = pickNearestAboveThreshold(candidates, threshold);
    if (candidate) {
      setActive(candidate, options);
    }
  }

  // Called for any in-page hash navigation, whether or not it targets a
  // tracked section (e.g. a footer link's "#components" jumps to a whole
  // ApiSection, not one sidebar entry). targetId is applied immediately
  // when it does match, for an instant, flicker-free highlight; either way,
  // scroll-driven updates stay locked until endSettling confirms where the
  // scroll actually landed.
  // Re-armed on every 'scroll' tick while settling (below), so it only
  // fires this many ms after scrolling genuinely stops - regardless of how
  // long the smooth-scroll animation itself takes. A fixed one-shot delay
  // can't work here: this page is tens of thousands of pixels tall, so a
  // full-length smooth-scroll can run past a second, and firing the
  // fallback before it actually finishes would lock in a mid-flight
  // position - worse, it clears `settling`, so the real 'scrollend' that
  // follows is then ignored too (see endSettling's guard).
  const SETTLE_IDLE_MS = 400;

  function beginSettling(targetId: string): void {
    settling = true;
    pendingTargetId = linkByTargetId.has(targetId) ? targetId : null;
    armSettleTimeout();
    if (pendingTargetId) {
      setActive(pendingTargetId);
    }
  }

  function armSettleTimeout(): void {
    window.clearTimeout(settleTimeout);
    // Also the sole guard for when no scroll happens at all - e.g. the
    // target was already in view - which fires no 'scroll' or 'scrollend'
    // events to re-arm or resolve this any other way.
    settleTimeout = window.setTimeout(endSettling, SETTLE_IDLE_MS);
  }

  // A target close enough to the bottom of the page - the CLI section is
  // the last thing on it - can run out of room to scroll: the browser
  // clamps to its max scroll position, which can leave the target on
  // screen but short of the header-offset threshold `pickNearestAbove
  // Threshold` looks for. Re-deriving the active link from geometry alone
  // would then credit whatever else happens to sit at that threshold
  // instead. If the actual clicked target is still visible at all once
  // settled, that beats any geometry guess - it's exactly what the user
  // asked for and the page could physically deliver.
  function isInViewport(id: string): boolean {
    const el = document.getElementById(id);
    if (!el || el.hidden) {
      return false;
    }
    const rect = el.getBoundingClientRect();
    return rect.bottom > 0 && rect.top < window.innerHeight;
  }

  function endSettling(): void {
    if (!settling) {
      return;
    }
    settling = false;
    window.clearTimeout(settleTimeout);
    if (pendingTargetId && isInViewport(pendingTargetId)) {
      setActive(pendingTargetId);
    } else {
      activateTopmostVisible();
    }
    pendingTargetId = null;
  }

  // Covers the sidebar's own links, the footer's "back to top", and the
  // header brand link - every in-page hash link on the page - from one
  // place, rather than re-deriving this per component.
  document.addEventListener('click', (event) => {
    const anchor = (event.target as HTMLElement).closest<HTMLAnchorElement>('a[href^="#"]');
    if (!anchor) {
      return;
    }
    beginSettling(anchor.getAttribute('href')!.slice(1));
  });

  window.addEventListener('hashchange', () => {
    beginSettling(window.location.hash.slice(1));
  });

  window.addEventListener(
    'scroll',
    () => {
      if (settling) {
        armSettleTimeout();
      }
    },
    { passive: true },
  );

  window.addEventListener('scrollend', endSettling);

  if (typeof IntersectionObserver !== 'undefined') {
    const headerOffset = document.querySelector('.topbar')?.clientHeight ?? 0;
    const threshold = headerOffset + 24;
    // IntersectionObserver callbacks only report entries whose intersection
    // state *changed* since the last firing, not every target currently
    // intersecting, so the full intersecting set is tracked here across
    // calls. Each entry is a whole section (heading + examples + a
    // screenshot), which can run taller than the observed band, so among
    // everything currently intersecting the active link must still be
    // chosen with pickNearestAboveThreshold - the same "closest to, but
    // still above, the threshold" rule the no-IntersectionObserver fallback
    // below uses - rather than by naively taking the smallest top, which
    // instead picks whichever section has scrolled furthest UP off screen.
    const intersecting = new Map<string, IntersectionObserverEntry>();
    const observer = new IntersectionObserver(
      (observedEntries) => {
        observedEntries.forEach((observed) => {
          if (observed.isIntersecting && !(observed.target as HTMLElement).hidden) {
            intersecting.set(observed.target.id, observed);
          } else {
            intersecting.delete(observed.target.id);
          }
        });
        const candidates = [...intersecting.entries()].map(([id, entry]) => ({
          id,
          top: entry.boundingClientRect.top,
        }));
        const candidate = pickNearestAboveThreshold(candidates, threshold);
        if (!settling && candidate) {
          setActive(candidate);
        }
      },
      {
        rootMargin: `-${headerOffset + 1}px 0px -65% 0px`,
        threshold: 0,
      },
    );
    targets.forEach((target) => observer.observe(target));
  } else {
    let ticking = false;
    window.addEventListener('scroll', () => {
      if (ticking) {
        return;
      }
      ticking = true;
      window.requestAnimationFrame(() => {
        if (!settling) {
          activateTopmostVisible();
        }
        ticking = false;
      });
    });
  }

  if (!activateFromHash({ scrollNavIntoView: false })) {
    activateTopmostVisible({ scrollNavIntoView: false });
  }
}

// Owns the sidebar's search field: dispatches FILTER_EVENT for
// ApiEntry/FunctionRow instances to react to (see their own listeners),
// plus the "/" shortcut to focus it from anywhere on the page.
function setupSearch(): void {
  const searchInput = docsNav?.querySelector<HTMLInputElement>('.docs-nav__search-input');
  if (!searchInput) {
    return;
  }

  searchInput.addEventListener('input', () => {
    const query = searchInput.value.trim().toLowerCase();
    document.dispatchEvent(new CustomEvent(FILTER_EVENT, { detail: { query } }));
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === '/' && document.activeElement !== searchInput) {
      event.preventDefault();
      searchInput.focus();
    }
  });
}

// React to search-filter results reported by ApiEntry/FunctionRow
// instances elsewhere on the page, without ever querying their DOM
// directly.
function setupFilterSync(): void {
  document.addEventListener(ENTRY_VISIBILITY_EVENT, (event) => {
    const { id, visible } = (event as CustomEvent<EntryVisibilityDetail>).detail;
    const link = navLinks.find((candidate) => candidate.dataset.navFor === id);
    const item = link?.closest<HTMLElement>('.docs-nav__item');
    if (item) {
      item.hidden = !visible;
    }
    navGroupEls.forEach((group) => {
      group.hidden = !group.querySelector('.docs-nav__item:not([hidden])');
    });
  });
}

setupFilterSync();

if (!screenshotName) {
  setupMobileNav();
  setupScrollSpy();
  setupSearch();
}
