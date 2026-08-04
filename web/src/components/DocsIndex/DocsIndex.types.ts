export interface IndexLink {
  href: string;
  number: string;
  label: string;
  count: number;
}

export interface Props {
  totalCount: number;
  links: IndexLink[];
}
