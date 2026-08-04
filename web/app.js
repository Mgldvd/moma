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

const BASH_KEYWORDS = new Set([
  'if', 'then', 'else', 'elif', 'fi', 'for', 'do', 'done', 'while',
  'case', 'esac', 'function', 'select', 'until',
]);

function escapeHtml(value) {
  return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// Find the index of the ')' that closes the '(' at openIndex, accounting
// for nested parentheses. Returns -1 when the source has no closing paren.
function findMatchingParen(source, openIndex) {
  let depth = 0;
  for (let k = openIndex; k < source.length; k += 1) {
    if (source[k] === '(') {
      depth += 1;
    } else if (source[k] === ')') {
      depth -= 1;
      if (depth === 0) {
        return k;
      }
    }
  }
  return -1;
}

// Highlight a $variable, ${variable}, or single-character parameter ($!,
// $?, $1, ...) starting at source[start] === '$'. $(...) command
// substitution is handled by its caller, not here.
function renderVariable(source, start) {
  const n = source.length;
  let end = start + 1;

  if (source[end] === '{') {
    end += 1;
    while (end < n && source[end] !== '}') {
      end += 1;
    }
    if (end < n) {
      end += 1;
    }
  } else if (/[A-Za-z_]/.test(source[end] || '')) {
    end += 1;
    while (end < n && /[A-Za-z0-9_]/.test(source[end])) {
      end += 1;
    }
  } else if (/[!?@#*0-9]/.test(source[end] || '')) {
    end += 1;
  }

  const text = source.slice(start, end);
  return { html: `<span class="tok-variable">${escapeHtml(text)}</span>`, next: end };
}

// Highlight the interior of a "..." string, recursively highlighting any
// $(...) command substitution or $variable it contains so nested commands
// keep their own token colors instead of being flattened to string color.
function renderDoubleQuoted(source, start) {
  const n = source.length;
  let i = start + 1;
  let buffer = '';
  let html = '<span class="tok-string">"';

  while (i < n && source[i] !== '"') {
    const ch = source[i];

    if (ch === '\\') {
      buffer += source.slice(i, i + 2);
      i += 2;
      continue;
    }

    if (ch === '$' && source[i + 1] === '(') {
      const closeIndex = findMatchingParen(source, i + 1);
      const end = closeIndex === -1 ? n : closeIndex;
      const inner = renderTokens(source.slice(i + 2, end), true);
      html += `${escapeHtml(buffer)}</span><span class="tok-subst">$(${inner}${closeIndex === -1 ? '' : ')'}</span><span class="tok-string">`;
      buffer = '';
      i = closeIndex === -1 ? n : closeIndex + 1;
      continue;
    }

    if (ch === '$') {
      const variable = renderVariable(source, i);
      html += `${escapeHtml(buffer)}</span>${variable.html}<span class="tok-string">`;
      buffer = '';
      i = variable.next;
      continue;
    }

    buffer += ch;
    i += 1;
  }

  html += escapeHtml(buffer);
  const closed = i < n;
  html += `${closed ? '"' : ''}</span>`;
  return { html, next: closed ? i + 1 : i };
}

// Highlight one Bash source string (a single command or several commands
// joined by ;, &&, ||, |, or newlines) as HTML with token spans for
// comments, strings, variables, command substitutions, flags, keywords,
// and the command name that starts each statement. This is a small
// hand-written lexer, not a full parser, so it only needs to cover the
// literal syntax used in the reference examples and quick-start snippets
// on this page: no external highlighting library is loaded.
function renderTokens(source, atCommandStartInitial) {
  const n = source.length;
  let out = '';
  let i = 0;
  let atCommandStart = atCommandStartInitial;

  while (i < n) {
    const ch = source[i];

    if (ch === ' ' || ch === '\t') {
      out += ch;
      i += 1;
      continue;
    }
    if (ch === '\n') {
      out += '\n';
      i += 1;
      atCommandStart = true;
      continue;
    }
    if (ch === '#') {
      let end = source.indexOf('\n', i);
      end = end === -1 ? n : end;
      out += `<span class="tok-comment">${escapeHtml(source.slice(i, end))}</span>`;
      i = end;
      atCommandStart = false;
      continue;
    }
    if (ch === "'") {
      let end = i + 1;
      while (end < n && source[end] !== "'") {
        end += 1;
      }
      const closed = end < n;
      if (closed) {
        end += 1;
      }
      out += `<span class="tok-string">${escapeHtml(source.slice(i, end))}</span>`;
      i = end;
      atCommandStart = false;
      continue;
    }
    if (ch === '"') {
      const result = renderDoubleQuoted(source, i);
      out += result.html;
      i = result.next;
      atCommandStart = false;
      continue;
    }
    if (ch === '$' && source[i + 1] === '(') {
      const closeIndex = findMatchingParen(source, i + 1);
      const end = closeIndex === -1 ? n : closeIndex;
      const inner = renderTokens(source.slice(i + 2, end), true);
      out += `<span class="tok-subst">$(${inner}${closeIndex === -1 ? '' : ')'}</span>`;
      i = closeIndex === -1 ? n : closeIndex + 1;
      atCommandStart = false;
      continue;
    }
    if (ch === '$') {
      const variable = renderVariable(source, i);
      out += variable.html;
      i = variable.next;
      atCommandStart = false;
      continue;
    }
    if (ch === '(') {
      out += escapeHtml(ch);
      i += 1;
      atCommandStart = true;
      continue;
    }
    if (ch === ';' || ch === '&' || ch === '|') {
      let end = i + 1;
      if ((ch === '&' && source[end] === '&') || (ch === '|' && source[end] === '|')) {
        end += 1;
      }
      out += escapeHtml(source.slice(i, end));
      i = end;
      atCommandStart = true;
      continue;
    }
    if (/[A-Za-z0-9_./~-]/.test(ch)) {
      let end = i;
      while (end < n && /[A-Za-z0-9_./~-]/.test(source[end])) {
        end += 1;
      }
      const word = source.slice(i, end);
      let cls = null;
      if (/^--?[A-Za-z]/.test(word)) {
        cls = 'tok-flag';
      } else if (BASH_KEYWORDS.has(word)) {
        cls = 'tok-keyword';
      } else if (/^[0-9][0-9.]*$/.test(word)) {
        cls = 'tok-number';
      } else if (atCommandStart) {
        cls = 'tok-command';
      }
      out += cls ? `<span class="${cls}">${escapeHtml(word)}</span>` : escapeHtml(word);
      i = end;
      atCommandStart = BASH_KEYWORDS.has(word);
      continue;
    }

    out += escapeHtml(ch);
    i += 1;
    atCommandStart = false;
  }

  return out;
}

// Highlight one Bash snippet as HTML for insertion into a `.tok-*`-styled
// <code> element via innerHTML.
function highlightBashSyntax(source) {
  return renderTokens(source, true);
}

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

// Copy plain text (never highlighted HTML) to the clipboard, falling back
// to the legacy execCommand path for browsers without the async Clipboard
// API, and show a transient "Copied" state on the triggering button
// either way.
function copyTextToClipboard(text, button) {
  function announceCopied() {
    window.clearTimeout(button.dataset.copyResetTimer);
    button.textContent = 'Copied';
    button.dataset.copied = 'true';
    button.setAttribute('aria-label', 'Copied to clipboard');
    button.dataset.copyResetTimer = window.setTimeout(() => {
      button.textContent = 'Copy';
      delete button.dataset.copied;
      button.setAttribute('aria-label', 'Copy command to clipboard');
    }, 1500);
  }

  function legacyCopy() {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.setAttribute('readonly', '');
    textarea.style.position = 'fixed';
    textarea.style.left = '-9999px';
    document.body.append(textarea);
    textarea.select();
    try {
      if (document.execCommand('copy')) {
        announceCopied();
      }
    } catch {
      // Copying is unsupported in this browser; leave the button as-is.
    } finally {
      textarea.remove();
    }
  }

  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(text).then(announceCopied, legacyCopy);
  } else {
    legacyCopy();
  }
}

// Add a "Copy" button to a container that copies a fixed block of plain
// text. Positioning comes from CSS: absolute within a .code-block or
// .api-examples__example, or in normal flow when the container is a flex
// row such as .quick-start__label.
function addCopyButton(container, text, label) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'copy-btn';
  button.textContent = 'Copy';
  button.setAttribute('aria-label', label || 'Copy command to clipboard');
  button.addEventListener('click', () => copyTextToClipboard(text, button));
  container.append(button);
  return button;
}

// Give a bare <code> block (.signature) a positioned wrapper so its copy
// button has a stable anchor even when the code itself scrolls
// horizontally.
function wrapCodeWithCopyButton(codeEl) {
  const wrapper = document.createElement('div');
  wrapper.className = 'code-block';
  codeEl.replaceWith(wrapper);
  wrapper.append(codeEl);
  addCopyButton(wrapper, codeEl.textContent);
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
    exampleCode.innerHTML = highlightBashSyntax(example);
    exampleBlock.append(exampleCode);
    addCopyButton(exampleBlock, example);
    exampleList.append(exampleBlock);
  });

  exampleSection.append(exampleTitle, exampleList);
  entry.querySelector('.wireframe')?.before(exampleSection);
});

// Each hero quick-start group (Preview, Load, Install) gets one copy
// button that copies every command in that group, not one button per
// command line.
document.querySelectorAll('.quick-start').forEach((group) => {
  const label = group.querySelector('.quick-start__label');
  const commands = [...group.querySelectorAll('.quick-start__command')];
  if (!label || commands.length === 0) {
    return;
  }

  const groupName = label.textContent.trim();
  const combinedText = commands.map((command) => command.textContent).join('\n');
  commands.forEach((command) => {
    command.innerHTML = highlightBashSyntax(command.textContent);
  });
  addCopyButton(label, combinedText, `Copy ${groupName} commands to clipboard`);
});

document.querySelectorAll('.signature').forEach((signature) => {
  wrapCodeWithCopyButton(signature);
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
