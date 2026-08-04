import { highlightBashSyntax } from '../../utils/bashHighlight';

document.querySelectorAll<HTMLElement>('.docs-hero .quick-start__command').forEach((command) => {
  command.innerHTML = highlightBashSyntax(command.textContent || '');
});
