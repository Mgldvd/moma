export interface Props {
  /** Exact plain text copied to the clipboard (never highlighted HTML). */
  text: string;
  /** Accessible label. Defaults to "Copy command to clipboard". */
  label?: string;
  /**
   * `floating` (default) positions the button absolutely over its
   * container, for use inside a `position: relative` wrapper such as a
   * code block. `inline` keeps it in normal flow, for use inside an
   * already flex/grid-laid-out row.
   */
  variant?: 'floating' | 'inline';
}
