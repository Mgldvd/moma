export interface Props {
  /** Text shown in the fake window chrome. Defaults to "preview". */
  title?: string;
  /** Accessible name for the terminal output region. */
  ariaLabel: string;
  /**
   * `pagga` removes body line-height so multi-row ASCII/pixel art glyphs
   * (moma-header's Pagga banner) stay flush with no vertical gap.
   */
  variant?: 'default' | 'pagga';
}
