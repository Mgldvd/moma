export interface FunctionRowData {
  id: string;
  name: string;
  description: string;
  signature: string;
}

export const FUNCTION_ROWS: FunctionRowData[] = [
  {
    id: 'cli-component-commands',
    name: 'Component commands',
    description: 'Call any visual component without sourcing the library.',
    signature: 'moma title | title-sub | section | msg | msg-simple | list | box | resume | prompt | label | input | select | single-select | single-select-groups | multi-select | multi-select-groups | rabbit',
  },
  {
    id: 'cli-helper-commands',
    name: 'Helper commands',
    description: 'Run confirmation, spinner, executable checks, and release operations.',
    signature: 'moma confirm | spinner | command-check | version | update',
  },
  {
    id: 'cli-color-themes',
    name: 'Color themes',
    description: 'Load themes from ~/.config/momaui/moma.confg, list them, or select one for a command.',
    signature: 'moma themes | moma --theme NAME msg "Ready"',
  },
  {
    id: 'cli-documentation-commands',
    name: 'Documentation commands',
    description: 'Open terminal, Markdown, web, or usage documentation.',
    signature: 'moma preview [md|web] | help',
  },
];
