// Site-wide configuration values. Not component-specific styling or
// markup - just the small set of facts (version, canonical repo) that
// multiple components and the page `<head>` legitimately need to agree
// on, analogous to an environment variable.
import { API_ENTRIES } from './apiEntries';

const visualComponentCount = API_ENTRIES.filter((entry) => entry.section === 'components').length;
const workflowHelperCount = API_ENTRIES.filter((entry) => entry.section === 'helpers').length;

export const SITE = {
  title: 'Moma Documentation — API Preview',
  description: 'Complete Moma Bash API and terminal component reference.',
  url: 'https://mgldvd.github.io/moma/',
  repoUrl: 'https://github.com/Mgldvd/moma',
  version: '1.3.0',
  // Derived from API_ENTRIES.length (rather than hardcoded) so adding or
  // removing an entry there updates every count shown across the site
  // (footer, hero, API index) without a second place to remember to edit.
  functionCount: API_ENTRIES.length,
  visualComponentCount,
  workflowHelperCount,
} as const;
