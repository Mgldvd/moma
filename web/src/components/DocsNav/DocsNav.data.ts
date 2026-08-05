import { API_ENTRIES, type ApiEntryNavGroup } from '../../data/apiEntries';
import { FUNCTION_ROWS } from '../../data/functionRows';
import type { NavGroup } from './DocsNav.types';

// The sidebar's grouping and order are derived entirely from API_ENTRIES
// and FUNCTION_ROWS - the same arrays index.astro renders the page from -
// instead of separate, hand-maintained id lists. Reordering or adding an
// entry there is therefore automatically reflected here, in the matching
// position, with no second place to keep in sync.
const GROUP_HEADINGS: Record<ApiEntryNavGroup, string> = {
  visual: 'Visual',
  interactive: 'Interactive',
  selection: 'Selection',
  workflow: 'Workflow',
};

const GROUP_ORDER: ApiEntryNavGroup[] = ['visual', 'interactive', 'selection', 'workflow'];

export const NAV_GROUPS: NavGroup[] = [
  ...GROUP_ORDER.map((key) => ({
    key,
    heading: GROUP_HEADINGS[key],
    links: API_ENTRIES.filter((entry) => entry.navGroup === key).map((entry) => ({
      label: entry.name,
      targetId: entry.id,
      filterable: true,
    })),
  })),
  {
    key: 'cli',
    heading: 'CLI',
    links: FUNCTION_ROWS.map((row) => ({ label: row.name, targetId: row.id })),
  },
];
