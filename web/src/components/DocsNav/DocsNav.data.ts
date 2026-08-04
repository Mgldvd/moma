import type { NavGroup } from './DocsNav.types';

const filterableLink = (id: string) => ({ label: id, targetId: id, filterable: true });

export const NAV_GROUPS: NavGroup[] = [
  {
    key: 'visual',
    heading: 'Visual',
    links: [
      'moma-header',
      'moma-title',
      'moma-title-sub',
      'moma-section',
      'moma-msg',
      'moma-msg-simple',
      'moma-list',
      'moma-box',
      'moma-block',
      'moma-prompt',
      'moma-label',
      'moma-rabbit',
    ].map(filterableLink),
  },
  {
    key: 'interactive',
    heading: 'Interactive',
    links: ['moma-input', 'moma-confirm'].map(filterableLink),
  },
  {
    key: 'selection',
    heading: 'Selection',
    links: [
      'moma-single-select',
      'moma-select',
      'moma-single-select-groups',
      'moma-multi-select',
      'moma-multi-select-groups',
    ].map(filterableLink),
  },
  {
    key: 'workflow',
    heading: 'Workflow',
    links: [
      'moma-spinner',
      'moma-command-check',
      'moma-version',
      'moma-update',
    ].map(filterableLink),
  },
  {
    key: 'cli',
    heading: 'CLI',
    links: [
      { label: 'Component commands', targetId: 'cli-component-commands' },
      { label: 'Helper commands', targetId: 'cli-helper-commands' },
      { label: 'Color themes', targetId: 'cli-color-themes' },
      { label: 'Documentation commands', targetId: 'cli-documentation-commands' },
    ],
  },
];
