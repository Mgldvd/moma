export type QuickStartIconName = 'terminal' | 'file' | 'apple' | 'linux';

export interface QuickStartGroup {
  label: string;
  commands: string[];
  /** Shown to the left of the copy button, in order. */
  icons?: QuickStartIconName[];
}

export interface Props {
  eyebrow?: string;
  quickStartGroups?: QuickStartGroup[];
}
