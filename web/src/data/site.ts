// Site-wide configuration values. Not component-specific styling or
// markup - just the small set of facts (version, canonical repo) that
// multiple components and the page `<head>` legitimately need to agree
// on, analogous to an environment variable.
export const SITE = {
  title: 'Moma Documentation — API Preview',
  description: 'Complete Moma Bash API and terminal component reference.',
  url: 'https://mgldvd.github.io/moma/',
  repoUrl: 'https://github.com/Mgldvd/moma',
  version: '1.3.0',
  functionCount: 23,
  visualComponentCount: 19,
  workflowHelperCount: 4,
} as const;
