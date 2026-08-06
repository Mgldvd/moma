// Site-wide configuration values. Not component-specific styling or
// markup - just the small set of facts (version, canonical repo) that
// multiple components and the page `<head>` legitimately need to agree
// on, analogous to an environment variable.
import { API_ENTRIES } from './apiEntries';

export const SITE = {
  title: 'Moma Documentation — API Preview',
  description: 'Complete Moma Bash API and terminal component reference.',
  url: 'https://mgldvd.github.io/moma/',
  repoUrl: 'https://github.com/Mgldvd/moma',
  version: '2.0.0',
  // Derived from API_ENTRIES.length (rather than hardcoded) so adding or
  // removing an entry there updates every count shown across the site
  // (footer) without a second place to remember to edit.
  functionCount: API_ENTRIES.length,
} as const;
