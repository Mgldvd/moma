import type { QuickStartGroup } from './Hero.types';

export const QUICK_START_GROUPS: QuickStartGroup[] = [
  {
    label: 'Preview',
    icons: ['terminal'],
    commands: [
      'bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview',
    ],
  },
  {
    label: 'Load',
    icons: ['terminal', 'file'],
    commands: [
      'source <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma)',
      'moma msg "Ready" --success',
    ],
  },
  {
    label: 'Install',
    icons: ['apple', 'linux'],
    commands: [
      'mkdir -p "$HOME/.local/bin"',
      'curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma -o "$HOME/.local/bin/moma"',
      'chmod 0755 "$HOME/.local/bin/moma"',
    ],
  },
];
