export interface Props {
  id: string;
  title: string;
  intro: string;
  /**
   * Filterable sections hide themselves when none of their ApiEntry
   * children match the active search query (or, in screenshot mode, when
   * they don't contain the targeted entry). The CLI section is not
   * filterable: it has no ApiEntry children, only FunctionRow rows, which
   * never participate in search.
   */
  filterable?: boolean;
}
