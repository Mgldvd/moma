// Hex values match screenshots/moma_screenshots/palette.py exactly, so
// these swatches show the same colors moma's real terminal screenshots
// render with, not an approximation of them.
export interface NamedColor {
  name: string;
  hex: string;
}

export interface SemanticColor {
  state: string;
  flag: string;
  icon: string;
  colorName: string;
  hex: string;
}

export const SEMANTIC_COLORS: SemanticColor[] = [
  { state: 'Success', flag: '--success', icon: '✔', colorName: 'green', hex: '#73f59a' },
  { state: 'Error', flag: '--error', icon: '✖', colorName: 'red', hex: '#ff7676' },
  { state: 'Warning', flag: '--warning', icon: '!', colorName: 'yellow', hex: '#f9dc66' },
  { state: 'Info', flag: '--info', icon: '→', colorName: 'cyan', hex: '#68e4ff' },
];

export const NAMED_COLORS: NamedColor[] = [
  { name: 'black', hex: '#1c2333' },
  { name: 'red', hex: '#ff7676' },
  { name: 'green', hex: '#73f59a' },
  { name: 'yellow', hex: '#f9dc66' },
  { name: 'blue', hex: '#4f8be0' },
  { name: 'purple', hex: '#b389f9' },
  { name: 'cyan', hex: '#68e4ff' },
  { name: 'white', hex: '#f5f1f7' },
  { name: 'pink', hex: '#ff90e7' },
  { name: 'gray', hex: '#c8c8c8' },
];

export const DEFAULT_COLOR_NAME = 'cyan';
