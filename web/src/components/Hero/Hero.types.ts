export interface QuickStartGroup {
  label: string;
  commands: string[];
}

export interface Props {
  eyebrow?: string;
  quickStartGroups?: QuickStartGroup[];
}
