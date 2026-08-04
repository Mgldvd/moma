export interface NavLink {
  label: string;
  /** id of the on-page target this link scrolls/jumps to. */
  targetId: string;
  /**
   * True when this link corresponds to a searchable API entry and should
   * hide itself when that entry is filtered out. CLI links are always
   * visible.
   */
  filterable?: boolean;
}

export interface NavGroup {
  key: string;
  heading: string;
  links: NavLink[];
}
