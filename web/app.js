const root = document.documentElement;
const themeToggle = document.querySelector('.theme-toggle');
const searchInput = document.querySelector('.search__input');
const count = document.querySelector('.docs-index__count');
const entries = [...document.querySelectorAll('[data-api]')];
const groups = [...document.querySelectorAll('[data-group]')];
const emptyState = document.querySelector('.empty-state');
const screenshotName = new URLSearchParams(window.location.search).get('component');
const componentExamples = {
  'moma-header': [
    'moma-header "Moma"',
    'moma-header "Deploy 2026" --color cyan --margin-bottom 1',
    'moma-header "Build ready" --margin-top 0 --margin-bottom 0 --margin-left 2 --no-color',
  ],
  'moma-title': [
    'moma-title "Moma" "Terminal UI library"',
    'moma-title "Deploy" "Production" --primary cyan',
    'moma-title "Backup" "Nightly job" --accent yellow --min-width 48',
  ],
  'moma-title-sub': [
    'moma-title-sub "Dependencies" "Installing packages"',
    'moma-title-sub "Deploy" "Production" --color cyan',
    'moma-title-sub "Tests" --message "Running suite" --min-width 42',
  ],
  'moma-section': [
    'moma-section "Dependencies ready" --success',
    'moma-section "Configuration failed" --error',
    'moma-section "Next step" --info --icon "→"',
  ],
  'moma-msg': [
    'moma-msg "Package installed" --success',
    'moma-msg "Connection refused" --error',
    'moma-msg "Downloading metadata" --color cyan --icon "→"',
  ],
  'moma-msg-simple': [
    'moma-msg-simple "Package installed"',
    'moma-msg-simple "Package installation failed" --error',
    'moma-msg-simple "Queued" --color yellow --marker "•"',
  ],
  'moma-list': [
    'moma-list "Clone repository" "Install dependencies" "Start application"',
    'moma-list "Database ready" "Cache ready" --success',
    'moma-list "Review logs" "Retry deployment" --marker "→" --color yellow',
  ],
  'moma-box': [
    'moma-box "Configuration is ready." --success',
    'moma-box "Review the deployment settings." --warning --width 48',
    'moma-box "A long notice wraps inside its border." --info --max-width 32',
  ],
  'moma-prompt': [
    'moma-prompt "Continue with the installation?"',
    'moma-prompt "Select an environment" --color cyan',
    'moma-prompt "Deploy now?" --default "yes" --icon "?"',
  ],
  'moma-label': [
    'moma-label "PROJECT NAME"',
    'moma-label "DEPLOYMENT" --success',
    'moma-label "NOTES" --width 52 --color cyan --icon "→"',
  ],
  'moma-input': [
    'moma-input --title "Project name" --placeholder "my-project"',
    'project="$(moma-input --title "Project name" --read --required --trim)"',
    'password="$(moma-input --title "Password" --read --secret --required)"',
  ],
  'moma-select': [
    'environment="$(moma-select "Development" "Staging" "Production" --title "Environment")"',
    'environment="$(moma-select "Development" "Staging" "Production" --choose 2)"',
    'region="$(moma-select "US" "EU" "APAC" --title "Region" --initial 2 --color cyan)"',
  ],
  'moma-multi-select': [
    'features="$(moma-multi-select "Docker" "CI" "Tests" --title "Features")"',
    'features="$(moma-multi-select "Docker" "CI" "Tests" --choose 1,3)"',
    'features="$(moma-multi-select "Docker" "CI" "Tests" --selected 1,2 --required)"',
  ],
  'moma-rabbit': [
    'moma-rabbit "Preparing workspace" --info',
    'moma-rabbit "Deployment complete" --success',
    'moma-rabbit "Build needs attention" --warning --icon "!"',
  ],
  'moma-confirm': [
    'moma-confirm "Create this project?" --default yes',
    'moma-confirm "Delete the cache?" --answer no',
    'if moma-confirm "Deploy now?"; then\n  moma-msg "Deploying" --info\nfi',
  ],
  'moma-spinner': [
    'sleep 2 &\nmoma-spinner "$!" "Waiting"',
    'backup_database &\nmoma-spinner --pid "$!" --message "Backing up"',
    'build_project &\nmoma-spinner "$!" "Building" --delay 0.05',
  ],
  'moma-command-check': [
    'moma-command-check bash curl git',
    'moma-command-check docker --quiet',
    'if ! moma-command-check git; then\n  exit 1\nfi',
  ],
  'moma-version': [
    'moma version',
    'moma-version',
  ],
  'moma-update': [
    'moma update',
    'moma-update',
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
