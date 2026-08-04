import { SITE } from './site';

export interface ApiEntryWireframe {
  variant?: 'default' | 'pagga';
  /** Raw, trusted, build-time-authored HTML - preserves exact terminal
   * whitespace and `.tw-*` color spans copied from the source site. */
  bodyHtml: string;
}

export interface ApiEntryData {
  id: string;
  kind: string;
  name: string;
  /** Raw, trusted, build-time-authored HTML (usually plain text; one
   * entry embeds inline <code>). */
  descriptionHtml: string;
  signature: string;
  searchText: string;
  examples?: string[];
  wireframe?: ApiEntryWireframe;
}

export const API_ENTRIES: ApiEntryData[] = [
  {
    id: 'moma-header',
    kind: 'ASCII heading component',
    name: 'moma-header',
    descriptionHtml: 'Three-line Pagga text for a prominent script or workflow identity, with one blank line above, two below, and no left indent by default.',
    signature: 'moma header "TEXT" [--color color] [--margin-top number] [--margin-bottom number] [--margin-left number] [--no-color]',
    searchText: 'moma-header pagga ascii art heading title color',
    examples: [
      'moma header "Moma"',
      'moma header "Deploy 2026" --color cyan --margin-bottom 1',
      'moma header "Build ready" --margin-top 0 --margin-bottom 0 --margin-left 2 --no-color',
    ],
    wireframe: {
      variant: 'pagga',
      bodyHtml: `<span class="tw-primary">░█▄█░█▀█░█▄█░█▀█
░█░█░█░█░█░█░█▀█
░▀░▀░▀▀▀░▀░▀░▀░▀</span>`,
    },
  },
  {
    id: 'moma-title',
    kind: 'Heading component',
    name: 'moma-title',
    descriptionHtml: 'Primary identity block for the beginning of a script or major workflow.',
    signature: 'moma title "Moma" "Terminal UI library" [--primary color] [--accent color] [--width number] [--max-width number]',
    searchText: 'moma-title primary script header title subtitle accent',
    examples: [
      'moma title "Moma" "Terminal UI library"',
      'moma title "Deploy" "Production" --primary cyan',
      'moma title "Backup" "Nightly job" --accent yellow --min-width 48',
    ],
    wireframe: {
      bodyHtml: `
<span class="tw-accent">  ┌───────────────────────────────────┐
  ▪  </span><span class="tw-primary">Moma</span><span class="tw-accent"> Terminal UI library         ▪
  └───────────────────────────────────┘</span>`,
    },
  },
  {
    id: 'moma-title-sub',
    kind: 'Heading component',
    name: 'moma-title-sub',
    descriptionHtml: 'Secondary heading for stages nested inside the main workflow.',
    signature: 'moma title-sub "Deployment" "Production environment" [--width number] [--max-width number]',
    searchText: 'moma-title-sub secondary workflow header subtitle',
    examples: [
      'moma title-sub "Dependencies" "Installing packages"',
      'moma title-sub "Deploy" "Production" --color cyan',
      'moma title-sub "Tests" --message "Running suite" --min-width 42',
    ],
    wireframe: {
      bodyHtml: `
<span class="tw-accent">  ▪  </span><span class="tw-primary">Deployment</span> Production environment
  └───────────────────────────────────────
`,
    },
  },
  {
    id: 'moma-section',
    kind: 'Section component',
    name: 'moma-section',
    descriptionHtml: 'Strong separator that gives semantic context to the content that follows.',
    signature: 'moma section "Dependencies ready" --success',
    searchText: 'moma-section semantic heading success error warning info',
    examples: [
      'moma section "Dependencies ready" --success',
      'moma section "Configuration failed" --error',
      'moma section "Next step" --info --icon "→"',
    ],
    wireframe: {
      bodyHtml: `
<span class="tw-success">  ┌
  ▪ ✔ Dependencies ready
  └ </span>

<span class="tw-error">  ┌
  ▪ ✖ Configuration failed
  └ </span>

<span class="tw-warning">  ┌
  ▪ ! Review required
  └ </span>

<span class="tw-info">  ┌
  ▪ → Next step
  └ </span>`,
    },
  },
  {
    id: 'moma-msg',
    kind: 'Message component',
    name: 'moma-msg',
    descriptionHtml: 'Compact feedback with semantic defaults or custom color and icon overrides.',
    signature: 'moma msg "Package installed" --success [--color value] [--icon value]',
    searchText: 'moma-msg message inline feedback icon success error warning info',
    examples: [
      'moma msg "Package installed" --success',
      'moma msg "Connection refused" --error',
      'moma msg "Downloading metadata" --color cyan --icon "→"',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-success">  ▪ ✔ Package installed  ✔ </span>
<span class="tw-error">  ▪ ✖ Connection refused  ✖ </span>
<span class="tw-warning">  ▪ ! Using cached version  ! </span>
<span class="tw-info">  ▪ → Downloading metadata  → </span>`,
    },
  },
  {
    id: 'moma-msg-simple',
    kind: 'Simple message',
    name: 'moma-msg-simple',
    descriptionHtml: 'A quiet message with only a dot marker and no semantic icon.',
    signature: 'moma msg-simple "Package installed" [--success|--error|--warning|--info] [--color value]',
    searchText: 'moma-msg-simple simple message dot marker no icon success error warning info semantic',
    examples: [
      'moma msg-simple "Package installed"',
      'moma msg-simple "Package installation failed" --error',
      'moma msg-simple "Queued" --color yellow --marker "•"',
    ],
    wireframe: {
      bodyHtml: `  <span class="tw-primary">▪</span>   Package installed
  <span class="tw-error">▪</span>   Package installation failed`,
    },
  },
  {
    id: 'moma-list',
    kind: 'List component',
    name: 'moma-list',
    descriptionHtml: 'An unordered terminal list with a consistent marker for every item.',
    signature: 'moma list "Clone repository" "Install dependencies" [--success|--error|--warning|--info]',
    searchText: 'moma-list unordered list items dot marker success error warning info semantic',
    examples: [
      'moma list "Clone repository" "Install dependencies" "Start application"',
      'moma list "Database ready" "Cache ready" --success',
      'moma list "Review logs" "Retry deployment" --marker "→" --color yellow',
    ],
    wireframe: {
      bodyHtml: `  <span class="tw-primary">▪</span>   Clone repository
  <span class="tw-primary">▪</span>   Install dependencies
  <span class="tw-primary">▪</span>   Start application`,
    },
  },
  {
    id: 'moma-box',
    kind: 'Notice component',
    name: 'moma-box',
    descriptionHtml: 'Framed notice with automatic, fixed, or maximum width. Long content wraps inside the border.',
    signature: 'moma box "Configuration is ready." --success [--width number] [--max-width number]',
    searchText: 'moma-box framed boxed notice emphasis success warning info error width max-width MOMA_WIDTH MOMA_MAX_WIDTH',
    examples: [
      'moma box "Configuration is ready." --success',
      'moma box "Review the deployment settings." --warning --width 48',
      'moma box "A long notice wraps inside its border." --info --max-width 32',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-success">  ┌───────────────────────────┐
  │ ✔ Configuration is ready. │
  └───────────────────────────┘</span>`,
    },
  },
  {
    id: 'moma-prompt',
    kind: 'Prompt component',
    name: 'moma-prompt',
    descriptionHtml: 'Question lead-in used before confirmation or free-form interaction.',
    signature: 'moma prompt "Continue with the installation?" --color pink [--width number] [--max-width number]',
    searchText: 'moma-prompt question confirmation interaction',
    examples: [
      'moma prompt "Continue with the installation?"',
      'moma prompt "Select an environment" --color cyan',
      'moma prompt "Deploy now?" --default "yes" --icon "?"',
    ],
    wireframe: {
      bodyHtml: `
<span class="tw-accent">  ▪</span>  Continue with the installation?
  └─────────────────────────────────────`,
    },
  },
  {
    id: 'moma-label',
    kind: 'Label component',
    name: 'moma-label',
    descriptionHtml: 'Print an input-style decorated label with automatic width, semantic color support, and one blank line below it.',
    signature: 'moma label "TEXT HERE" [--width number] [--max-width number] [--color color] [--icon symbol]',
    searchText: 'moma-label decorated input header separator text width color semantic',
    examples: [
      'moma label "PROJECT NAME"',
      'moma label "DEPLOYMENT" --success',
      'moma label "NOTES" --width 52 --color cyan --icon "→"',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-primary">  ┌─ TEXT HERE ────────────────────────────┐</span>
`,
    },
  },
  {
    id: 'moma-input',
    kind: 'Input component',
    name: 'moma-input',
    descriptionHtml: 'Display or read a field with placeholders, validation, secret masking, and one blank line below each interactive value.',
    signature: 'moma input --title "Project name" --read --required [--secret] [--mask symbol] [--default value] [--width number] [--max-width number]',
    searchText: 'moma-input interactive field read value placeholder secret required default trim',
    examples: [
      'moma input --title "Project name" --placeholder "my-project"',
      'project="$(moma input --title "Project name" --read --required --trim)"',
      'password="$(moma input --title "Password" --read --secret --required)"',
    ],
    wireframe: {
      bodyHtml: `  ┌─ Owner ────────────────────────────────┐
  │ <span class="tw-muted">asdf</span>                                   │
  └────────────────────────────────────────┘

  ┌─ Secret ───────────────────────────────┐
  │❯ <span class="tw-muted">****</span>
`,
    },
  },
  {
    id: 'moma-single-select',
    kind: 'Select component',
    name: 'moma-single-select',
    descriptionHtml: 'Select one value with the arrow keys, return it through standard output, and leave one blank line below the controls.',
    signature: 'moma single-select "Development" "Staging" "Production" [--title text] [--initial number]',
    searchText: 'moma-single-select interactive selection list arrows up down radio choice',
    examples: [
      'environment="$(moma single-select "Development" "Staging" "Production" --title "Environment")"',
      'environment="$(moma single-select "Development" "Staging" "Production" --choose 2)"',
      'region="$(moma single-select "US" "EU" "APAC" --title "Region" --initial 2 --color cyan)"',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-accent">  ▪  </span>Environment
<span class="tw-primary">  └──────────────────────────────</span>
    <span class="tw-primary">○</span> Development
<span class="tw-focus">  › ◉ Staging</span>
    <span class="tw-primary">○</span> Production
<span class="tw-muted">  ↑/↓ move · Enter select · q cancel</span>`,
    },
  },
  {
    id: 'moma-select',
    kind: 'Select component',
    name: 'moma-select',
    descriptionHtml: 'Documented compatibility alias for <code>moma-single-select</code>. Same arguments, same rendering, kept for existing scripts and the <code>select</code> CLI command.',
    signature: 'moma select "Development" "Staging" "Production" [--title text] [--initial number]',
    searchText: 'moma-select interactive selection alias compatibility single-select',
    examples: [
      'environment="$(moma select "Development" "Staging" "Production" --title "Environment")"',
    ],
    // No wireframe: matches the source site, where this entry has never
    // had a terminal preview - see ApiEntry's note on the Bash-examples
    // block being skipped here too, for the same reason.
  },
  {
    id: 'moma-single-select-groups',
    kind: 'Select component',
    name: 'moma-single-select-groups',
    descriptionHtml: 'Select one value organized under named, non-selectable group headings. Option numbers are one-based, count only options, and follow visual order across every group.',
    signature: 'moma single-select-groups --title text (--group name --option value...)... [--initial number] [--choose number]',
    searchText: 'moma-single-select-groups interactive selection list arrows up down radio choice groups headings',
    examples: [
      'action="$(moma single-select-groups --title "Features" --group "Docker" --option "Up" --option "Down" --option "Stop" --group "npm" --option "install" --option "run dev" --option "run deploy")"',
      'action="$(moma single-select-groups --title "Features" --group "Docker" --option "Up" --option "Down" --option "Stop" --group "npm" --option "install" --option "run dev" --option "run deploy" --choose 4)"',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-accent">  ▪  </span>Features
<span class="tw-primary">  └──────────────────────────────</span>

<span class="tw-muted">    Docker</span>
<span class="tw-focus">  › ◉ Up</span>
    <span class="tw-primary">○</span> Down
    <span class="tw-primary">○</span> Stop

<span class="tw-muted">    npm</span>
    <span class="tw-primary">○</span> install
    <span class="tw-primary">○</span> run dev
    <span class="tw-primary">○</span> run deploy
<span class="tw-muted">  ↑/↓ move · Enter select · q cancel</span>`,
    },
  },
  {
    id: 'moma-multi-select',
    kind: 'Multiple select',
    name: 'moma-multi-select',
    descriptionHtml: 'Toggle multiple values below a decorated Moma heading and return every selection on its own line.',
    signature: 'moma multi-select "Docker" "CI" "Tests" [--selected 1,3] [--required]',
    searchText: 'moma-multi-select interactive multiple selection list arrows space checkbox empty filled square',
    examples: [
      'features="$(moma multi-select "Docker" "CI" "Tests" --title "Features")"',
      'features="$(moma multi-select "Docker" "CI" "Tests" --choose 1,3)"',
      'features="$(moma multi-select "Docker" "CI" "Tests" --selected 1,2 --required)"',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-accent">  ▪  </span>Features
<span class="tw-primary">  └──────────────────────────────</span>
<span class="tw-focus">  › </span><span class="tw-selected">▣</span> Docker
    <span class="tw-primary">□</span> CI
    <span class="tw-selected">▣</span> Tests
<span class="tw-muted">  ↑/↓ move · Space toggle · Enter confirm · q cancel</span>`,
    },
  },
  {
    id: 'moma-multi-select-groups',
    kind: 'Multiple select',
    name: 'moma-multi-select-groups',
    descriptionHtml: 'Toggle multiple values organized under named, non-selectable group headings and return every selection on its own line, in original visual order.',
    signature: 'moma multi-select-groups --title text (--group name --option value...)... [--selected numbers] [--choose numbers] [--required]',
    searchText: 'moma-multi-select-groups interactive multiple selection list arrows space checkbox empty filled square groups headings',
    examples: [
      'countries="$(moma multi-select-groups --title "Features" --group "North America" --option "United States" --option "Canada" --option "Mexico" --group "South America" --option "Colombia" --option "Argentina" --option "Peru")"',
      'countries="$(moma multi-select-groups --title "Features" --group "North America" --option "United States" --option "Canada" --option "Mexico" --group "South America" --option "Colombia" --option "Argentina" --option "Peru" --choose 1,3 --required)"',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-accent">  ▪  </span>Features
<span class="tw-primary">  └──────────────────────────────</span>

<span class="tw-muted">    North America</span>
<span class="tw-focus">  › </span><span class="tw-selected">▣</span> United States
    <span class="tw-primary">□</span> Canada
    <span class="tw-selected">▣</span> Mexico

<span class="tw-muted">    South America</span>
    <span class="tw-primary">□</span> Colombia
    <span class="tw-primary">□</span> Argentina
    <span class="tw-primary">□</span> Peru
<span class="tw-muted">  ↑/↓ move · Space toggle · Enter confirm · q cancel</span>`,
    },
  },
  {
    id: 'moma-confirm',
    kind: 'Confirmation select',
    name: 'moma-confirm',
    descriptionHtml: 'Select Yes or No with the arrow keys, Enter, or the y and n shortcuts. A successful answer leaves one blank line below the controls.',
    signature: 'moma confirm "Create this project?" [--default yes|no] [--answer yes|no]',
    searchText: 'moma-confirm interactive confirmation yes no selection arrows shortcut default answer',
    examples: [
      'moma confirm "Create this project?" --default yes',
      'moma confirm "Delete the cache?" --answer no',
      'if moma confirm "Deploy now?"; then\n  moma msg "Deploying" --info\nfi',
    ],
    wireframe: {
      bodyHtml: `
<span class="tw-accent">  ▪  </span>Create this project? [yes]
<span class="tw-primary">  └────────────────────────────────</span>
<span class="tw-focus">  ▪ Yes</span>
    No
<span class="tw-muted">  ↑/↓ move · Enter confirm · y yes · n no</span>`,
    },
  },
  {
    id: 'moma-rabbit',
    kind: 'Activity component',
    name: 'moma-rabbit',
    descriptionHtml: "Branded activity and completion feedback using Moma's rabbit signature.",
    signature: 'moma rabbit "Preparing workspace" --info',
    searchText: 'moma-rabbit branded progress activity mascot success info',
    examples: [
      'moma rabbit "Preparing workspace" --info',
      'moma rabbit "Deployment complete" --success',
      'moma rabbit "Build needs attention" --warning --icon "!"',
    ],
    wireframe: {
      bodyHtml: `
<span class="tw-info">  | → Preparing workspace
  /⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺</span>

<span class="tw-accent">    (\\(\\
    (-.-)
  o_(")(")</span>`,
    },
  },
  {
    id: 'moma-spinner',
    kind: 'Process helper',
    name: 'moma-spinner',
    descriptionHtml: 'Display progress while a process is active, then print semantic completion feedback.',
    signature: 'moma spinner pid ["message"] [--delay seconds]',
    searchText: 'moma-spinner progress pid process completion',
    examples: [
      'sleep 2 &\nmoma spinner "$!" "Waiting"',
      'backup_database &\nmoma spinner --pid "$!" --message "Backing up"',
      'build_project &\nmoma spinner "$!" "Building" --delay 0.05',
    ],
    wireframe: {
      bodyHtml: `<span class="tw-success">  ▪ ✔ Processing  ✔ </span>`,
    },
  },
  {
    id: 'moma-command-check',
    kind: 'Dependency helper',
    name: 'moma-command-check',
    descriptionHtml: 'Check whether every requested executable is available and return a useful status.',
    signature: 'moma command-check bash curl git [--quiet]',
    searchText: 'moma-command-check dependency executable available missing quiet',
    examples: [
      'moma command-check bash curl git',
      'moma command-check docker --quiet',
      'if ! moma command-check git; then\n  exit 1\nfi',
    ],
    wireframe: {
      bodyHtml: `  <span class="tw-primary">▪</span>   bash is available
  <span class="tw-primary">▪</span>   curl is available
  <span class="tw-primary">▪</span>   git is available`,
    },
  },
  {
    id: 'moma-version',
    kind: 'Release helper',
    name: 'moma-version',
    descriptionHtml: 'Print the version embedded in the installed Moma executable.',
    signature: 'moma version',
    searchText: 'moma-version installed release version',
    examples: ['moma version'],
    wireframe: {
      bodyHtml: SITE.version,
    },
  },
  {
    id: 'moma-update',
    kind: 'Release helper',
    name: 'moma-update',
    descriptionHtml: 'Download, validate, and atomically replace an executable Moma installation.',
    signature: 'moma update',
    searchText: 'moma-update upgrade download release curl',
    examples: ['moma update'],
    wireframe: {
      bodyHtml: `  <span class="tw-primary">▪</span>   moma: updated successfully`,
    },
  },
];
