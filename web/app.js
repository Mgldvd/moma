const root = document.documentElement;
root.classList.remove('no-js');
root.classList.add('js');

const themeToggle = document.querySelector('.theme-toggle');
const searchInput = document.querySelector('.search__input');
const count = document.querySelector('.docs-index__count');
const entries = [...document.querySelectorAll('[data-api]')];
const groups = [...document.querySelectorAll('[data-group]')];
const emptyState = document.querySelector('.empty-state');
const screenshotName = new URLSearchParams(window.location.search).get('component');

const navToggle = document.querySelector('.nav-toggle');
const docsNav = document.querySelector('.docs-nav');
const docsNavClose = document.querySelector('.docs-nav__close');
const docsNavBackdrop = document.querySelector('.docs-nav-backdrop');
const navLinks = [...document.querySelectorAll('.docs-nav__link')];
const navGroupEls = [...document.querySelectorAll('.docs-nav__group')];

const componentExamples = {
  'moma-header': [
    'moma header "Moma"',
    'moma header "Deploy 2026" --color cyan --margin-bottom 1',
    'moma header "Build ready" --margin-top 0 --margin-bottom 0 --margin-left 2 --no-color',
  ],
  'moma-title': [
    'moma title "Moma" "Terminal UI library"',
    'moma title "Deploy" "Production" --primary cyan',
    'moma title "Backup" "Nightly job" --accent yellow --min-width 48',
  ],
  'moma-title-sub': [
    'moma title-sub "Dependencies" "Installing packages"',
    'moma title-sub "Deploy" "Production" --color cyan',
    'moma title-sub "Tests" --message "Running suite" --min-width 42',
  ],
  'moma-section': [
    'moma section "Dependencies ready" --success',
    'moma section "Configuration failed" --error',
    'moma section "Next step" --info --icon "→"',
  ],
  'moma-msg': [
    'moma msg "Package installed" --success',
    'moma msg "Connection refused" --error',
    'moma msg "Downloading metadata" --color cyan --icon "→"',
  ],
  'moma-msg-simple': [
    'moma msg-simple "Package installed"',
    'moma msg-simple "Package installation failed" --error',
    'moma msg-simple "Queued" --color yellow --marker "•"',
  ],
  'moma-list': [
    'moma list "Clone repository" "Install dependencies" "Start application"',
    'moma list "Database ready" "Cache ready" --success',
    'moma list "Review logs" "Retry deployment" --marker "→" --color yellow',
  ],
  'moma-box': [
    'moma box "Configuration is ready." --success',
    'moma box "Review the deployment settings." --warning --width 48',
    'moma box "A long notice wraps inside its border." --info --max-width 32',
  ],
  'moma-prompt': [
    'moma prompt "Continue with the installation?"',
    'moma prompt "Select an environment" --color cyan',
    'moma prompt "Deploy now?" --default "yes" --icon "?"',
  ],
  'moma-label': [
    'moma label "PROJECT NAME"',
    'moma label "DEPLOYMENT" --success',
    'moma label "NOTES" --width 52 --color cyan --icon "→"',
  ],
  'moma-input': [
    'moma input --title "Project name" --placeholder "my-project"',
    'project="$(moma input --title "Project name" --read --required --trim)"',
    'password="$(moma input --title "Password" --read --secret --required)"',
  ],
  'moma-single-select': [
    'environment="$(moma single-select "Development" "Staging" "Production" --title "Environment")"',
    'environment="$(moma single-select "Development" "Staging" "Production" --choose 2)"',
    'region="$(moma single-select "US" "EU" "APAC" --title "Region" --initial 2 --color cyan)"',
  ],
  'moma-select': [
    'environment="$(moma select "Development" "Staging" "Production" --title "Environment")"',
  ],
  'moma-single-select-groups': [
    'action="$(moma single-select-groups --title "Features" --group "Docker" --option "Up" --option "Down" --option "Stop" --group "npm" --option "install" --option "run dev" --option "run deploy")"',
    'action="$(moma single-select-groups --title "Features" --group "Docker" --option "Up" --option "Down" --option "Stop" --group "npm" --option "install" --option "run dev" --option "run deploy" --choose 4)"',
  ],
  'moma-multi-select': [
    'features="$(moma multi-select "Docker" "CI" "Tests" --title "Features")"',
    'features="$(moma multi-select "Docker" "CI" "Tests" --choose 1,3)"',
    'features="$(moma multi-select "Docker" "CI" "Tests" --selected 1,2 --required)"',
  ],
  'moma-multi-select-groups': [
    'countries="$(moma multi-select-groups --title "Features" --group "North America" --option "United States" --option "Canada" --option "Mexico" --group "South America" --option "Colombia" --option "Argentina" --option "Peru")"',
    'countries="$(moma multi-select-groups --title "Features" --group "North America" --option "United States" --option "Canada" --option "Mexico" --group "South America" --option "Colombia" --option "Argentina" --option "Peru" --choose 1,3 --required)"',
  ],
  'moma-rabbit': [
    'moma rabbit "Preparing workspace" --info',
    'moma rabbit "Deployment complete" --success',
    'moma rabbit "Build needs attention" --warning --icon "!"',
  ],
  'moma-confirm': [
    'moma confirm "Create this project?" --default yes',
    'moma confirm "Delete the cache?" --answer no',
    'if moma confirm "Deploy now?"; then\n  moma msg "Deploying" --info\nfi',
  ],
  'moma-spinner': [
    'sleep 2 &\nmoma spinner "$!" "Waiting"',
    'backup_database &\nmoma spinner --pid "$!" --message "Backing up"',
    'build_project &\nmoma spinner "$!" "Building" --delay 0.05',
  ],
  'moma-command-check': [
    'moma command-check bash curl git',
    'moma command-check docker --quiet',
    'if ! moma command-check git; then\n  exit 1\nfi',
  ],
  'moma-version': [
    'moma version',
  ],
  'moma-update': [
    'moma update',
  ],
};

const savedTheme = localStorage.getItem('moma-preview-theme');
if (savedTheme === 'light' || savedTheme === 'dark') {
  root.dataset.theme = savedTheme;
}

entries.forEach((entry) => {
  const componentName = entry.dataset.api.split(' ')[0];
  const examples = componentExamples[componentName];

  if (!examples) {
    return;
  }

  const exampleSection = document.createElement('section');
  const exampleTitle = document.createElement('p');
  const exampleList = document.createElement('div');

  exampleSection.className = 'api-examples';
  exampleTitle.className = 'api-examples__title';
  exampleTitle.textContent = 'Bash examples';
  exampleList.className = 'api-examples__list';

  examples.forEach((example) => {
    const exampleBlock = document.createElement('pre');
    const exampleCode = document.createElement('code');

    exampleBlock.className = 'api-examples__example';
    exampleCode.className = 'api-examples__code';
    exampleCode.textContent = example;
    exampleBlock.append(exampleCode);
    exampleList.append(exampleBlock);
  });

  exampleSection.append(exampleTitle, exampleList);
  entry.querySelector('.wireframe')?.before(exampleSection);
});

if (screenshotName) {
  const screenshotTarget = entries.find((entry) => (
    entry.dataset.api.split(' ')[0] === screenshotName
  ));

  root.dataset.theme = 'light';
  document.body.classList.add('page--screenshot');

  entries.forEach((entry) => {
    entry.hidden = entry !== screenshotTarget;
  });

  groups.forEach((group) => {
    group.hidden = !screenshotTarget || !group.contains(screenshotTarget);
  });

  if (screenshotTarget) {
    screenshotTarget.classList.add('component-preview--screenshot-target');
  }
}

function syncThemeButton() {
  const isDark = root.dataset.theme === 'dark';
  themeToggle.setAttribute('aria-pressed', String(isDark));
  themeToggle.setAttribute('aria-label', isDark ? 'Use light theme' : 'Use dark theme');
}

// Return the sidebar link's target component name, ignoring hidden entries.
function isNavLinkVisible(link) {
  const componentName = link.dataset.navFor;
  if (!componentName) {
    return true;
  }
  const entry = entries.find((candidate) => (
    candidate.dataset.api.split(' ')[0] === componentName
  ));
  return !entry || !entry.hidden;
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

  navLinks.forEach((link) => {
    const item = link.closest('.docs-nav__item');
    if (item) {
      item.hidden = !isNavLinkVisible(link);
    }
  });

  navGroupEls.forEach((group) => {
    group.hidden = !group.querySelector('.docs-nav__item:not([hidden])');
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

// Mobile component-navigation drawer. Desktop anchor navigation works from
// the static markup alone; this only layers on off-canvas open/close
// behavior for narrow viewports.
function setupMobileNav() {
  if (!navToggle || !docsNav || !docsNavBackdrop) {
    return;
  }

  const isNarrowViewport = () => window.matchMedia('(max-width: 959.98px)').matches;
  let lastFocused = null;

  function focusableElements() {
    return [...docsNav.querySelectorAll('a[href], button:not([disabled])')]
      .filter((element) => element.offsetParent !== null);
  }

  function onKeydown(event) {
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

  function openNav() {
    lastFocused = document.activeElement;
    docsNavBackdrop.hidden = false;
    navToggle.setAttribute('aria-expanded', 'true');
    // The same <nav> is a persistent landmark on desktop; only present it
    // as a modal dialog while it behaves like one, on mobile.
    docsNav.setAttribute('role', 'dialog');
    docsNav.setAttribute('aria-modal', 'true');
    document.body.style.overflow = 'hidden';
    requestAnimationFrame(() => {
      docsNav.dataset.open = 'true';
      docsNavBackdrop.dataset.open = 'true';
    });
    const focusables = focusableElements();
    (focusables[0] || docsNav).focus();
    document.addEventListener('keydown', onKeydown);
  }

  function closeNav({ restoreFocus = true } = {}) {
    docsNav.dataset.open = 'false';
    docsNavBackdrop.dataset.open = 'false';
    navToggle.setAttribute('aria-expanded', 'false');
    docsNav.removeAttribute('role');
    docsNav.removeAttribute('aria-modal');
    document.body.style.overflow = '';
    document.removeEventListener('keydown', onKeydown);
    window.setTimeout(() => {
      if (docsNav.dataset.open === 'false') {
        docsNavBackdrop.hidden = true;
      }
    }, 220);
    if (restoreFocus && lastFocused) {
      lastFocused.focus();
    }
  }

  function isOpen() {
    return docsNav.dataset.open === 'true';
  }

  navToggle.addEventListener('click', () => {
    if (isOpen()) {
      closeNav();
    } else {
      openNav();
    }
  });

  docsNavClose?.addEventListener('click', () => closeNav());
  docsNavBackdrop.addEventListener('click', () => closeNav());

  docsNav.addEventListener('click', (event) => {
    if (event.target.closest('a.docs-nav__link') && isOpen() && isNarrowViewport()) {
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
function setupScrollSpy() {
  if (navLinks.length === 0) {
    return;
  }

  const linkByTargetId = new Map();
  const targets = [];

  navLinks.forEach((link) => {
    const targetId = link.getAttribute('href').slice(1);
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
  function isNavOnScreen() {
    return window.matchMedia('(min-width: 960px)').matches || docsNav?.dataset.open === 'true';
  }

  // Whenever the sidebar's own list fits without overflowing (the common
  // desktop case), every link is already inside its scrollable ancestor's
  // viewport, so scrollIntoView "escapes" to the next real scrollable
  // ancestor - the window - and drags the whole page back to wherever that
  // link sits. Scrolling docsNav.scrollTop directly keeps this contained to
  // the sidebar no matter what does or doesn't overflow.
  function scrollLinkIntoNavView(link) {
    const navRect = docsNav.getBoundingClientRect();
    const linkRect = link.getBoundingClientRect();
    if (linkRect.top < navRect.top) {
      docsNav.scrollTop -= navRect.top - linkRect.top;
    } else if (linkRect.bottom > navRect.bottom) {
      docsNav.scrollTop += linkRect.bottom - navRect.bottom;
    }
  }

  // scrollNavIntoView defaults to true so clicks, history navigation, and
  // scroll-driven updates keep the sidebar's own view in sync. It is
  // explicitly disabled for the very first activation on page load so this
  // never fights the browser's native scroll to a deep-linked anchor.
  function setActive(id, { scrollNavIntoView = true } = {}) {
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

  function visibleTargetIds() {
    return targets
      .filter((target) => !target.hidden)
      .map((target) => target.id);
  }

  function activateFromHash(options) {
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
  function activateTopmostVisible(options) {
    const headerOffset = document.querySelector('.topbar')?.offsetHeight ?? 0;
    const threshold = headerOffset + 24;
    let candidate = '';
    let candidateTop = -Infinity;
    for (const id of visibleTargetIds()) {
      const rect = document.getElementById(id).getBoundingClientRect();
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
      const targetId = link.getAttribute('href').slice(1);
      setActive(targetId);
    });
  });

  window.addEventListener('hashchange', () => {
    activateFromHash();
  });

  if ('IntersectionObserver' in window) {
    const headerOffset = document.querySelector('.topbar')?.offsetHeight ?? 0;
    const observer = new IntersectionObserver(
      (observedEntries) => {
        const visible = observedEntries
          .filter((observed) => observed.isIntersecting && !observed.target.hidden)
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

if (!screenshotName) {
  setupMobileNav();
  setupScrollSpy();
}
