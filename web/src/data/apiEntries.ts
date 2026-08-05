export interface ApiEntryWireframe {
  /** Raw, trusted, build-time-authored HTML - preserves exact terminal
   * whitespace and `.tw-*` color spans copied from the source site. Only
   * used as a fallback for entries with no real screenshot (see
   * screenshots.ts / getScreenshot): moma-update performs a real network
   * install with no safe way to automate one, and moma-preview/moma-help's
   * real output (a full component gallery, a full command listing) is far
   * taller than the screenshot tool's fixed capture canvas - both wireframes
   * are a short, honest excerpt rather than a misleadingly cropped capture. */
  bodyHtml: string;
}

/**
 * Both the sidebar's grouping (see DocsNav.data.ts) and the page's own
 * section layout (see index.astro) - one heading, in this same order,
 * feeds both. `decorative`/`utils`/`self` split what used to be a single
 * catch-all "Workflow" group: `moma-rabbit` is purely decorative, spinner/
 * command-check are process utilities, and update/version/preview/help are
 * all "moma talking about itself" rather than terminal UI to build with.
 */
export type ApiEntryGroup = 'visual' | 'interactive' | 'selection' | 'decorative' | 'utils' | 'self';

/** One row of the signature's collapsible options table - the flag (or
 * positional form) exactly as it appears in `signature`, and a plain-
 * English description verified against the real Bash implementation, not
 * just paraphrased from the signature string. */
export interface ApiEntryOption {
  flag: string;
  description: string;
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
  group: ApiEntryGroup;
  examples?: string[];
  /** Every flag/positional form from `signature`, documented in detail.
   * Renders as a table the signature's own toggle button expands - see
   * ApiEntry.astro. Omitted entirely for signatures with no flags. */
  options?: ApiEntryOption[];
  wireframe?: ApiEntryWireframe;
}

export const API_ENTRIES: ApiEntryData[] = [
  {
    id: 'moma-header',
    kind: 'ASCII heading component',
    name: 'header',
    descriptionHtml: 'Three-line Pagga text for a prominent script or workflow identity, with one blank line above, two below, and no left indent by default.',
    signature: 'moma header "TEXT" [--color color] [--margin-top number] [--margin-bottom number] [--margin-left number] [--no-color]',
    searchText: 'moma-header pagga ascii art heading title color',
    group: 'visual',
    examples: [
      'moma header "Moma"',
      'moma header "Deploy 2026" --color cyan --margin-bottom 1',
      'moma header "Build ready" --margin-top 0 --margin-bottom 0 --margin-left 2 --no-color',
    ],
    options: [
      { flag: '--color <color>', description: 'Sets the heading color. Defaults to the primary color (cyan) when omitted.' },
      { flag: '--margin-top <number>', description: 'Blank lines printed above the heading. Defaults to 1.' },
      { flag: '--margin-bottom <number>', description: 'Blank lines printed below the heading. Defaults to 2.' },
      { flag: '--margin-left <number>', description: 'Spaces of left indent before every line. Defaults to 0.' },
      { flag: '--no-color', description: 'Strips ANSI color codes entirely, printing plain text.' },
    ],
  },
  {
    id: 'moma-title',
    kind: 'Heading component',
    name: 'title',
    descriptionHtml: 'Primary identity block for the beginning of a script or major workflow.',
    signature: 'moma title "Moma" "Terminal UI library" [--success|--error|--warning|--info] [--primary color] [--accent color] [--icon char] [--no-icon] [--border mirror|line|open] [--width number] [--max-width number]',
    searchText: 'moma-title primary script header title subtitle accent icon marker border mirror line open success error warning info',
    group: 'visual',
    examples: [
      'moma title "Moma" "Terminal UI library"',
      'moma title "Deploy" "Production" --primary cyan',
      'moma title "Backup" "Nightly job" --accent yellow --min-width 48',
      'moma title "Moma" "Terminal UI library" --success --border line',
      'moma title "Moma" "Terminal UI library" --no-icon --border open',
    ],
    options: [
      { flag: '--success | --error | --warning | --info', description: 'Sets the border/icon color and the left marker to the matching semantic icon (✔, ✖, !, →).' },
      { flag: '--primary <color>', description: 'Sets the box border and title text color. Defaults to the primary color (cyan) when omitted.' },
      { flag: '--accent <color>', description: 'Sets the subtitle text color. Defaults to the accent color (yellow) when omitted.' },
      { flag: '--icon <char>', description: 'Sets the left marker. Defaults to ▪.' },
      { flag: '--no-icon', description: 'Drops the left marker in favor of a plain box edge (│).' },
      { flag: '--border mirror | line | open', description: "Controls the right marker: mirror (default) repeats the left marker, line closes with a plain edge instead, open drops the right side entirely." },
      { flag: '--min-width <number>', description: 'Minimum box width in characters. Defaults to 35.' },
      { flag: '--width <number>', description: 'Forces an exact box width, overriding automatic sizing. Unset by default.' },
      { flag: '--max-width <number>', description: 'Caps the box width when the content would be wider. Unset by default.' },
    ],
  },
  {
    id: 'moma-title-sub',
    kind: 'Heading component',
    name: 'title-sub',
    descriptionHtml: 'Secondary heading for stages nested inside the main workflow.',
    signature: 'moma title-sub "Deployment" "Production environment" [--width number] [--max-width number]',
    searchText: 'moma-title-sub secondary workflow header subtitle',
    group: 'visual',
    examples: [
      'moma title-sub "Dependencies" "Installing packages"',
      'moma title-sub "Deploy" "Production" --color cyan',
      'moma title-sub "Tests" --message "Running suite" --min-width 42',
    ],
    options: [
      { flag: '--color <color>', description: 'Sets the rule and text color. Defaults to the primary color (cyan) when omitted.' },
      { flag: '--message <text>', description: 'An optional extra line printed below the rule, after a blank line. Omitted by default.' },
      { flag: '--min-width <number>', description: 'Minimum width in characters. Defaults to 30.' },
      { flag: '--width <number>', description: 'Forces an exact width, overriding automatic sizing. Unset by default.' },
      { flag: '--max-width <number>', description: 'Caps the width when the content would be wider. Unset by default.' },
    ],
  },
  {
    id: 'moma-section',
    kind: 'Section component',
    name: 'section',
    descriptionHtml: 'Strong separator that gives semantic context to the content that follows.',
    signature: 'moma section "Dependencies ready" --success',
    searchText: 'moma-section semantic heading success error warning info',
    group: 'visual',
    examples: [
      'moma section "Dependencies ready" --success',
      'moma section "Configuration failed" --error',
      'moma section "Next step" --info --icon "→"',
    ],
    options: [
      { flag: '--success | --error | --warning | --info', description: 'Semantic shortcuts that set both the heading color and its default icon (green ✔, red ✖, yellow !, cyan →).' },
      { flag: '--icon <icon>', description: 'Overrides the icon shown before the text.' },
    ],
  },
  {
    id: 'moma-msg',
    kind: 'Message component',
    name: 'msg',
    descriptionHtml: 'Compact feedback with semantic defaults or custom color and icon overrides.',
    signature: 'moma msg "Package installed" --success [--color value] [--icon value]',
    searchText: 'moma-msg message inline feedback icon success error warning info',
    group: 'visual',
    examples: [
      'moma msg "Package installed" --success',
      'moma msg "Connection refused" --error',
      'moma msg "Downloading metadata" --color cyan --icon "→"',
    ],
    options: [
      { flag: '--success | --error | --warning | --info', description: 'Semantic shortcuts that set both the message color and its default icon (green ✔, red ✖, yellow !, cyan →).' },
      { flag: '--color <value>', description: 'Overrides the message color. Defaults to the primary color (cyan) when omitted.' },
      { flag: '--icon <value>', description: 'Overrides the icon shown around the text. No icon is shown by default unless a semantic flag sets one.' },
    ],
  },
  {
    id: 'moma-msg-simple',
    kind: 'Simple message',
    name: 'msg-simple',
    descriptionHtml: 'A quiet message with only a dot marker and no semantic icon.',
    signature: 'moma msg-simple "Package installed" [--success|--error|--warning|--info] [--color value]',
    searchText: 'moma-msg-simple simple message dot marker no icon success error warning info semantic',
    group: 'visual',
    examples: [
      'moma msg-simple "Package installed"',
      'moma msg-simple "Package installation failed" --error',
      'moma msg-simple "Queued" --color yellow --marker "•"',
    ],
    options: [
      { flag: '--success | --error | --warning | --info', description: 'Sets just the marker color to the semantic color (green, red, yellow, cyan) - this component never shows an icon.' },
      { flag: '--color <value>', description: 'Overrides the marker color. Defaults to the primary color (cyan) when omitted.' },
      { flag: '--marker <marker>', description: 'Overrides the leading marker glyph. Defaults to "▪".' },
    ],
  },
  {
    id: 'moma-list',
    kind: 'List component',
    name: 'list',
    descriptionHtml: 'An unordered terminal list with a consistent marker for every item.',
    signature: 'moma list "Clone repository" "Install dependencies" [--success|--error|--warning|--info]',
    searchText: 'moma-list unordered list items dot marker success error warning info semantic',
    group: 'visual',
    examples: [
      'moma list "Clone repository" "Install dependencies" "Start application"',
      'moma list "Database ready" "Cache ready" --success',
      'moma list "Review logs" "Retry deployment" --marker "→" --color yellow',
    ],
    options: [
      { flag: '--success | --error | --warning | --info', description: 'Sets the marker color for every item to the semantic color (green, red, yellow, cyan).' },
      { flag: '--marker <marker>', description: 'Overrides the marker glyph shown before each item. Defaults to "▪".' },
      { flag: '--color <value>', description: 'Overrides the marker color for every item. Defaults to the primary color (cyan) when omitted.' },
    ],
  },
  {
    id: 'moma-box',
    kind: 'Notice component',
    name: 'box',
    descriptionHtml: 'Framed notice with automatic, fixed, or maximum width. Long content wraps inside the border.',
    signature: 'moma box "Configuration is ready." --success [--width number] [--max-width number]',
    searchText: 'moma-box framed boxed notice emphasis success warning info error width max-width MOMA_WIDTH MOMA_MAX_WIDTH',
    group: 'visual',
    examples: [
      'moma box "Configuration is ready." --success',
      'moma box "Review the deployment settings." --warning --width 48',
      'moma box "A long notice wraps inside its border." --info --max-width 32',
    ],
    options: [
      { flag: '--success | --error | --warning | --info', description: 'Sets both the border/text color and a default leading icon (green ✔, red ✖, yellow !, cyan →).' },
      { flag: '--width <number>', description: 'Forces an exact box width. Unset by default.' },
      { flag: '--max-width <number>', description: 'Caps the box width when the content would be wider. Unset by default.' },
    ],
  },
  {
    id: 'moma-resume',
    kind: 'Content block component',
    name: 'resume',
    descriptionHtml: 'Titled, colored content block for grouping related information, such as a résumé section or a categorized reference list. Rows come from repeated <code>--item</code> (a bold term next to a muted description, aligned as a column) and <code>--text</code> (a plain line), interleaved in the order given. The title is a single open line by default; setting an icon switches to a boxed header, mirroring <code>moma-title</code>\'s own marker conventions.',
    signature: 'moma resume --title "<text>" [--item "term" "description"]... [--text "line"]... [--success|--error|--warning|--info] [--color color] [--icon char] [--no-icon] [--border mirror|line|open] [--width number] [--max-width number] [--no-color]',
    searchText: 'moma-resume resume block by blocks definition list term description column grouped section color item text icon marker border mirror line open boxed header',
    group: 'visual',
    examples: [
      'moma resume --title "Shells" --color blue --item "Bash" "GNU command shell." --item "Zsh" "Interactive shell with completion."',
      'moma resume --title "Summary" --text "All checks passed." --text "No manual follow-up required."',
      'moma resume --title "Review" --warning --item "Environment" "production" --text "Confirm the target before deploying."',
      'moma resume --title "Moma Terminal UI library" --no-icon --border open --text "element 1" --text "element 2"',
    ],
    options: [
      { flag: '--title <text>', description: 'Required block heading text. The component errors if this is never supplied.' },
      { flag: '--item <term> <description>', description: 'Repeatable. Adds one row with a bold term and a muted description, all terms aligned to the widest one in the block.' },
      { flag: '--text <line>', description: 'Repeatable. Adds one row of plain text with no term column.' },
      { flag: '--success | --error | --warning | --info', description: 'Sets the border/title color to the semantic color and switches on the boxed header with the matching icon (✔, ✖, !, →).' },
      { flag: '--color <color>', description: "Sets the block's border/title color. Defaults to the primary color (cyan) when omitted." },
      { flag: '--icon <char>', description: 'Switches on the boxed header with this character as its left marker.' },
      { flag: '--no-icon', description: 'Switches on the boxed header with a plain box edge (│) instead of a marker.' },
      { flag: '--border mirror | line | open', description: 'Controls the closing edge: mirror and line (default: mirror) close with └, open leaves the block unclosed.' },
      { flag: '--width <number>', description: 'Forces an exact top-border width for the boxed header. Unset by default.' },
      { flag: '--max-width <number>', description: 'Caps the top-border width for the boxed header. Unset by default.' },
      { flag: '--no-color', description: 'Strips ANSI color codes entirely.' },
    ],
  },
  {
    id: 'moma-prompt',
    kind: 'Prompt component',
    name: 'prompt',
    descriptionHtml: 'Question lead-in used before confirmation or free-form interaction.',
    signature: 'moma prompt "Continue with the installation?" --color pink [--width number] [--max-width number]',
    searchText: 'moma-prompt question confirmation interaction',
    group: 'visual',
    examples: [
      'moma prompt "Continue with the installation?"',
      'moma prompt "Select an environment" --color cyan',
      'moma prompt "Deploy now?" --default "yes" --icon "?"',
    ],
    options: [
      { flag: '--color <color>', description: 'Sets the prompt color. Defaults to the warning color (yellow), not cyan, when omitted.' },
      { flag: '--width <number>', description: 'Forces an exact width. Unset by default.' },
      { flag: '--max-width <number>', description: 'Caps the width when the content would be wider. Unset by default.' },
      { flag: '--default <value>', description: 'Text appended in brackets after the question as a visual default hint, e.g. "Continue? [yes]". Nothing shown if omitted.' },
      { flag: '--icon <icon>', description: 'The leading glyph shown before the question. Defaults to "▪".' },
    ],
  },
  {
    id: 'moma-label',
    kind: 'Label component',
    name: 'label',
    descriptionHtml: 'Print an input-style decorated label with automatic width, semantic color support, and one blank line below it.',
    signature: 'moma label "TEXT HERE" [--width number] [--max-width number] [--color color] [--icon symbol]',
    searchText: 'moma-label decorated input header separator text width color semantic',
    group: 'visual',
    examples: [
      'moma label "PROJECT NAME"',
      'moma label "DEPLOYMENT" --success',
      'moma label "NOTES" --width 52 --color cyan --icon "→"',
    ],
    options: [
      { flag: '--width <number>', description: 'Forces an exact label width. Unset by default.' },
      { flag: '--max-width <number>', description: 'Caps the label width when the content would be wider. Unset by default.' },
      { flag: '--color <color>', description: 'Sets the label border/text color. Defaults to the primary color (cyan) when omitted.' },
      { flag: '--icon <symbol>', description: 'An icon shown before the label text. None by default.' },
      { flag: '--success | --error | --warning | --info', description: 'Sets both the color and a default icon together.' },
    ],
  },
  {
    id: 'moma-input',
    kind: 'Input component',
    name: 'input',
    descriptionHtml: 'Display or read a field with placeholders, validation, secret masking, and one blank line below each interactive value.',
    signature: 'moma input --title "Project name" --read --required [--secret] [--mask symbol] [--default value] [--width number] [--max-width number]',
    searchText: 'moma-input interactive field read value placeholder secret required default trim',
    group: 'interactive',
    examples: [
      'moma input --title "Project name" --placeholder "my-project"',
      'project="$(moma input --title "Project name" --read --required --trim)"',
      'password="$(moma input --title "Password" --read --secret --required)"',
    ],
    options: [
      { flag: '--title <text>', description: 'Label text shown above the field. Empty by default.' },
      { flag: '--placeholder <text>', description: "Text displayed as the field's value only when no --default and no --value are set. Empty by default." },
      { flag: '--default <value>', description: 'Fallback value used for display, and substituted in --read mode if the typed response is empty. Empty by default.' },
      { flag: '--width <number>', description: 'Forces an exact field width. Unset by default.' },
      { flag: '--max-width <number>', description: 'Caps the field width when the content would be wider. Unset by default.' },
      { flag: '--secret', description: 'Only meaningful with --read. Masks each typed character instead of echoing it.' },
      { flag: '--mask <symbol>', description: 'The character echoed for each keystroke when --secret is used. Defaults to "*".' },
      { flag: '--read', description: 'Switches from a static print into interactively reading one line of input from the terminal.' },
      { flag: '--required', description: 'Only meaningful with --read. Re-prompts until a non-empty value is produced.' },
      { flag: '--trim', description: 'Only meaningful with --read. Strips leading/trailing whitespace from the entered value.' },
    ],
  },
  {
    id: 'moma-confirm',
    kind: 'Confirmation select',
    name: 'confirm',
    descriptionHtml: 'Select Yes or No with the arrow keys, Enter, or the y and n shortcuts. A successful answer leaves one blank line below the controls.',
    signature: 'moma confirm "Create this project?" [--default yes|no] [--answer yes|no]',
    searchText: 'moma-confirm interactive confirmation yes no selection arrows shortcut default answer',
    group: 'interactive',
    examples: [
      'moma confirm "Create this project?" --default yes',
      'moma confirm "Delete the cache?" --answer no',
      'if moma confirm "Deploy now?"; then\n  moma msg "Deploying" --info\nfi',
    ],
    options: [
      { flag: '--default <yes|no>', description: 'Which answer starts highlighted, and is used automatically on an empty Enter. Defaults to "yes".' },
      { flag: '--answer <yes|no>', description: 'Supplies the final answer directly and returns immediately without prompting - for scripts and tests. Interactive mode is used if omitted.' },
    ],
  },
  {
    id: 'moma-select',
    kind: 'Select component',
    name: 'select',
    descriptionHtml: 'Select one value with the arrow keys, return it through standard output, and leave one blank line below the controls. Also available as <code>moma single-select</code> for existing scripts.',
    signature: 'moma select "Development" "Staging" "Production" [--title text] [--initial number]',
    searchText: 'moma-select moma-single-select interactive selection list arrows up down radio choice alias compatibility',
    group: 'selection',
    examples: [
      'environment="$(moma select "Development" "Staging" "Production" --title "Environment")"',
      'environment="$(moma select "Development" "Staging" "Production" --choose 2)"',
      'region="$(moma select "US" "EU" "APAC" --title "Region" --initial 2 --color cyan)"',
    ],
    options: [
      { flag: '--title <text>', description: 'Heading shown above the option list. Defaults to "Select an option".' },
      { flag: '--choose <number>', description: 'One-based index to select immediately without any interactive prompt - intended for scripts and automation. Interactive mode is used if omitted.' },
      { flag: '--initial <number>', description: 'One-based index highlighted when the menu first opens. Defaults to 1.' },
      { flag: '--color <color>', description: 'Highlight color for the active row. Defaults to the primary color (cyan) when omitted.' },
    ],
  },
  {
    // id/screenshot stay "single-select-groups" - the real, invocable
    // command (`moma single-select-groups`, see src/core/registry.sh); only
    // the display name below is shortened to "select-groups", the way
    // "single-select" is shortened to "select" above. Unlike select,
    // single-select-groups has no `select-groups` alias in the CLI itself,
    // so the signature/examples keep the real command name.
    id: 'moma-single-select-groups',
    kind: 'Select component',
    name: 'select-groups',
    descriptionHtml: 'Select one value organized under named, non-selectable group headings. Option numbers are one-based, count only options, and follow visual order across every group.',
    signature: 'moma single-select-groups --title text (--group name --option value...)... [--initial number] [--choose number]',
    searchText: 'moma-single-select-groups select-groups interactive selection list arrows up down radio choice groups headings',
    group: 'selection',
    examples: [
      'action="$(moma single-select-groups --title "Features" --group "Docker" --option "Up" --option "Down" --option "Stop" --group "npm" --option "install" --option "run dev" --option "run deploy")"',
      'action="$(moma single-select-groups --title "Features" --group "Docker" --option "Up" --option "Down" --option "Stop" --group "npm" --option "install" --option "run dev" --option "run deploy" --choose 4)"',
    ],
    options: [
      { flag: '--title <text>', description: 'Heading shown above the menu. Defaults to "Select an option".' },
      { flag: '--group <name>', description: 'Repeatable. Starts a new named, non-selectable group heading that following --option flags attach to. At least one is required.' },
      { flag: '--option <value>', description: 'Repeatable. Adds a selectable option under the most recently declared --group.' },
      { flag: '--initial <number>', description: 'One-based global option index (counting only options, not group headings) highlighted at start. Defaults to 1.' },
      { flag: '--choose <number>', description: 'One-based global option index to select immediately without interaction, for scripts and tests.' },
    ],
  },
  {
    id: 'moma-multi-select',
    kind: 'Multiple select',
    name: 'multi-select',
    descriptionHtml: 'Toggle multiple values below a decorated Moma heading and return every selection on its own line.',
    signature: 'moma multi-select "Docker" "CI" "Tests" [--selected 1,3] [--required]',
    searchText: 'moma-multi-select interactive multiple selection list arrows space checkbox empty filled square',
    group: 'selection',
    examples: [
      'features="$(moma multi-select "Docker" "CI" "Tests" --title "Features")"',
      'features="$(moma multi-select "Docker" "CI" "Tests" --choose 1,3)"',
      'features="$(moma multi-select "Docker" "CI" "Tests" --selected 1,2 --required)"',
    ],
    options: [
      { flag: '--title <text>', description: 'Heading shown above the menu. Defaults to "Select options".' },
      { flag: '--choose <numbers>', description: 'Comma-separated one-based indices to select immediately without interaction, for scripts and tests.' },
      { flag: '--selected <numbers>', description: 'Comma-separated one-based indices pre-checked before the menu is shown. None selected by default.' },
      { flag: '--required', description: 'Requires at least one option to be selected before confirming. Not required by default.' },
    ],
  },
  {
    id: 'moma-multi-select-groups',
    kind: 'Multiple select',
    name: 'multi-select-groups',
    descriptionHtml: 'Toggle multiple values organized under named, non-selectable group headings and return every selection on its own line, in original visual order.',
    signature: 'moma multi-select-groups --title text (--group name --option value...)... [--selected numbers] [--choose numbers] [--required]',
    searchText: 'moma-multi-select-groups interactive multiple selection list arrows space checkbox empty filled square groups headings',
    group: 'selection',
    examples: [
      'countries="$(moma multi-select-groups --title "Features" --group "North America" --option "United States" --option "Canada" --option "Mexico" --group "South America" --option "Colombia" --option "Argentina" --option "Peru")"',
      'countries="$(moma multi-select-groups --title "Features" --group "North America" --option "United States" --option "Canada" --option "Mexico" --group "South America" --option "Colombia" --option "Argentina" --option "Peru" --choose 1,3 --required)"',
    ],
    options: [
      { flag: '--title <text>', description: 'Heading shown above the menu. Defaults to "Select options".' },
      { flag: '--group <name>', description: 'Repeatable. Starts a named group, each with its own "All" toggle that selects/clears every option in that group at once.' },
      { flag: '--option <value>', description: 'Repeatable. Adds an option under the most recently declared --group.' },
      { flag: '--selected <numbers>', description: 'Comma-separated one-based global option indices pre-checked before the menu opens. None by default.' },
      { flag: '--choose <numbers>', description: 'Comma-separated one-based global option indices to select immediately without interaction, for scripts and tests.' },
      { flag: '--required', description: 'Requires at least one option selected before confirming. Not required by default.' },
    ],
  },
  {
    id: 'moma-rabbit',
    kind: 'Activity component',
    name: 'rabbit',
    descriptionHtml: "Branded activity and completion feedback using Moma's rabbit signature.",
    signature: 'moma rabbit "Preparing workspace" --info',
    searchText: 'moma-rabbit branded progress activity mascot success info decorative',
    group: 'decorative',
    examples: [
      'moma rabbit "Preparing workspace" --info',
      'moma rabbit "Deployment complete" --success',
      'moma rabbit "Build needs attention" --warning --icon "!"',
    ],
    options: [
      { flag: '--success | --error | --warning | --info', description: 'Sets both the message color and its default icon (green ✔, red ✖, yellow !, cyan →).' },
      { flag: '--icon <icon>', description: 'Overrides the icon shown before the message text. None by default.' },
    ],
  },
  {
    id: 'moma-spinner',
    kind: 'Process helper',
    name: 'spinner',
    descriptionHtml: 'Display progress while a process is active, then print semantic completion feedback.',
    signature: 'moma spinner pid ["message"] [--delay seconds]',
    searchText: 'moma-spinner progress pid process completion utility',
    group: 'utils',
    examples: [
      'sleep 2 &\nmoma spinner "$!" "Waiting"',
      'backup_database &\nmoma spinner --pid "$!" --message "Backing up"',
      'build_project &\nmoma spinner "$!" "Building" --delay 0.05',
    ],
    options: [
      { flag: '--pid <number>', description: 'The process ID to watch (can also be given as the first positional argument). Required.' },
      { flag: '--message <text>', description: 'Text shown next to the spinner, and reused as the completion message. Defaults to "Working" (can also be given as a second positional argument).' },
      { flag: '--delay <seconds>', description: 'Seconds between spinner-frame redraws. Defaults to 0.1.' },
    ],
  },
  {
    id: 'moma-command-check',
    kind: 'Dependency helper',
    name: 'command-check',
    descriptionHtml: 'Check whether every requested executable is available and return a useful status.',
    signature: 'moma command-check bash curl git [--quiet]',
    searchText: 'moma-command-check dependency executable available missing quiet utility',
    group: 'utils',
    examples: [
      'moma command-check bash curl git',
      'moma command-check docker --quiet',
      'if ! moma command-check git; then\n  exit 1\nfi',
    ],
    options: [
      { flag: '--quiet', description: 'Suppresses the per-command "available"/"missing" message lines. The return status still reflects availability.' },
    ],
  },
  {
    id: 'moma-update',
    kind: 'Release helper',
    name: 'update',
    descriptionHtml: 'Download, validate, and atomically replace an executable Moma installation.',
    signature: 'moma update',
    searchText: 'moma-update upgrade download release curl self',
    group: 'self',
    examples: ['moma update'],
    // No screenshot: this performs a real network install, so
    // screenshots/moma_screenshots/commands.py deliberately excludes it -
    // see that file's module docstring.
    wireframe: {
      bodyHtml: `  <span class="tw-primary">▪</span>   moma: updated successfully`,
    },
  },
  {
    id: 'moma-version',
    kind: 'Release helper',
    name: 'version',
    descriptionHtml: 'Print the version embedded in the installed Moma executable.',
    signature: 'moma version',
    searchText: 'moma-version installed release version self',
    group: 'self',
    examples: ['moma version'],
  },
  {
    id: 'moma-preview',
    kind: 'Documentation helper',
    name: 'preview',
    descriptionHtml: 'Show a categorized terminal, Markdown, or browser preview of every component, without leaving the CLI.',
    signature: 'moma preview [md|web]',
    searchText: 'moma-preview terminal markdown web gallery documentation browse self',
    group: 'self',
    examples: [
      'moma preview',
      'moma preview md',
      'moma preview web',
    ],
    options: [
      { flag: '(no argument)', description: 'Renders the full terminal component gallery to the screen.' },
      { flag: 'md', description: 'Renders the Markdown-form documentation instead of the terminal gallery.' },
      { flag: 'web', description: 'Opens the browser-based documentation instead of the terminal gallery.' },
    ],
    // No screenshot: the real terminal gallery walks through every
    // component in turn and runs far taller than the screenshot tool's
    // fixed capture canvas (screenshots/README.md's "every screenshot is
    // the same size" invariant) - this excerpt is the gallery's own real
    // opening banner (src/preview/main.sh's _moma_preview_header), not the
    // full scrolling output.
    wireframe: {
      bodyHtml: `  <span class="tw-muted">────────────────────────────────────────────────────────────────</span>
    MOMA  COMPONENT GALLERY
    Visual reference for the public terminal UI API
  <span class="tw-muted">────────────────────────────────────────────────────────────────</span>

    Legend  <span class="tw-success">● success</span>  <span class="tw-error">● error</span>  <span class="tw-warning">● warning</span>  <span class="tw-info">● info</span>
    ⋮`,
    },
  },
  {
    id: 'moma-help',
    kind: 'Documentation helper',
    name: 'help',
    descriptionHtml: 'Print full usage: every command, its description, and the global flags.',
    signature: 'moma help',
    searchText: 'moma-help usage commands options documentation self',
    group: 'self',
    examples: [
      'moma help',
      'moma --help',
      'moma -h',
    ],
    // No screenshot: the full command listing (one row per registered
    // command, src/core/registry.sh) runs taller than the screenshot
    // tool's fixed capture canvas - this excerpt is real usage text
    // (src/cli/usage.sh's _moma_usage_plain), just not the full listing.
    wireframe: {
      bodyHtml: `  Moma - terminal UI components for Bash

  Usage:
    moma &lt;command&gt; [arguments] [options]
    source dist/moma

  Commands:
    header                 Print a Pagga ASCII heading.
    msg                     Print a styled message.
    select                  Select one value (alias for single-select).
    <span class="tw-muted">⋮  every command and helper, one row each</span>

  Example:
    moma msg "Ready" --success`,
    },
  },
];
