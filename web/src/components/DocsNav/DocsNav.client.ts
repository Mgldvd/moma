import {
  ENTRY_VISIBILITY_EVENT,
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
// interacts with the page, so the mobile drawer and scroll-spy - both of
// which assume a normal viewport and user input - stay off in that mode.
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

  // Sidebar link order (grouped by category) does not match page scroll
  // order, so this scans every visible target rather than assuming an
  // already-sorted list and picks the one nearest to, but still above,
  // the threshold line below the sticky header.
  function activateTopmostVisible(options?: { scrollNavIntoView?: boolean }): void {
    const headerOffset = document.querySelector('.topbar')?.clientHeight ?? 0;
    const threshold = headerOffset + 24;
    let candidate = '';
    let candidateTop = -Infinity;
    for (const id of visibleTargetIds()) {
      const rect = document.getElementById(id)!.getBoundingClientRect();
      if (rect.top <= threshold && rect.top > candidateTop) {
        candidate = id;
        candidateTop = rect.top;
      }
    }
    if (candidate) {
      setActive(candidate, options);
    }
  }

  navLinks.forEach((link) => {
    link.addEventListener('click', () => {
      const targetId = link.getAttribute('href')!.slice(1);
      setActive(targetId);
    });
  });

  window.addEventListener('hashchange', () => {
    activateFromHash();
  });

  if (typeof IntersectionObserver !== 'undefined') {
    const headerOffset = document.querySelector('.topbar')?.clientHeight ?? 0;
    const observer = new IntersectionObserver(
      (observedEntries) => {
        const visible = observedEntries
          .filter((observed) => observed.isIntersecting && !(observed.target as HTMLElement).hidden)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible.length > 0) {
          setActive(visible[0].target.id);
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
        activateTopmostVisible();
        ticking = false;
      });
    });
  }

  if (!activateFromHash({ scrollNavIntoView: false })) {
    activateTopmostVisible({ scrollNavIntoView: false });
  }
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
}
