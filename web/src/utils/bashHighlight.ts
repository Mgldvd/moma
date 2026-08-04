// Small hand-written Bash lexer used to syntax-highlight the quick-start
// and per-component example commands as HTML with `.tok-*` token spans.
// It only needs to cover the literal syntax used in this page's own
// snippets, not arbitrary scripts, so no external highlighting library is
// loaded. Shared by Hero and ApiEntry, which both display example
// commands.

const BASH_KEYWORDS = new Set([
  'if', 'then', 'else', 'elif', 'fi', 'for', 'do', 'done', 'while',
  'case', 'esac', 'function', 'select', 'until',
]);

function escapeHtml(value: string): string {
  return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// Find the index of the ')' that closes the '(' at openIndex, accounting
// for nested parentheses. Returns -1 when the source has no closing paren.
function findMatchingParen(source: string, openIndex: number): number {
  let depth = 0;
  for (let k = openIndex; k < source.length; k += 1) {
    if (source[k] === '(') {
      depth += 1;
    } else if (source[k] === ')') {
      depth -= 1;
      if (depth === 0) {
        return k;
      }
    }
  }
  return -1;
}

// Highlight a $variable, ${variable}, or single-character parameter ($!,
// $?, $1, ...) starting at source[start] === '$'. $(...) command
// substitution is handled by its caller, not here.
function renderVariable(source: string, start: number): { html: string; next: number } {
  const n = source.length;
  let end = start + 1;

  if (source[end] === '{') {
    end += 1;
    while (end < n && source[end] !== '}') {
      end += 1;
    }
    if (end < n) {
      end += 1;
    }
  } else if (/[A-Za-z_]/.test(source[end] || '')) {
    end += 1;
    while (end < n && /[A-Za-z0-9_]/.test(source[end])) {
      end += 1;
    }
  } else if (/[!?@#*0-9]/.test(source[end] || '')) {
    end += 1;
  }

  const text = source.slice(start, end);
  return { html: `<span class="tok-variable">${escapeHtml(text)}</span>`, next: end };
}

// Highlight the interior of a "..." string, recursively highlighting any
// $(...) command substitution or $variable it contains so nested commands
// keep their own token colors instead of being flattened to string color.
function renderDoubleQuoted(source: string, start: number): { html: string; next: number } {
  const n = source.length;
  let i = start + 1;
  let buffer = '';
  let html = '<span class="tok-string">"';

  while (i < n && source[i] !== '"') {
    const ch = source[i];

    if (ch === '\\') {
      buffer += source.slice(i, i + 2);
      i += 2;
      continue;
    }

    if (ch === '$' && source[i + 1] === '(') {
      const closeIndex = findMatchingParen(source, i + 1);
      const end = closeIndex === -1 ? n : closeIndex;
      const inner = renderTokens(source.slice(i + 2, end), true);
      html += `${escapeHtml(buffer)}</span><span class="tok-subst">$(${inner}${closeIndex === -1 ? '' : ')'}</span><span class="tok-string">`;
      buffer = '';
      i = closeIndex === -1 ? n : closeIndex + 1;
      continue;
    }

    if (ch === '$') {
      const variable = renderVariable(source, i);
      html += `${escapeHtml(buffer)}</span>${variable.html}<span class="tok-string">`;
      buffer = '';
      i = variable.next;
      continue;
    }

    buffer += ch;
    i += 1;
  }

  html += escapeHtml(buffer);
  const closed = i < n;
  html += `${closed ? '"' : ''}</span>`;
  return { html, next: closed ? i + 1 : i };
}

// Highlight one Bash source string (a single command or several commands
// joined by ;, &&, ||, |, or newlines) as HTML with token spans for
// comments, strings, variables, command substitutions, flags, keywords,
// and the command name that starts each statement. This is a small
// hand-written lexer, not a full parser.
function renderTokens(source: string, atCommandStartInitial: boolean): string {
  const n = source.length;
  let out = '';
  let i = 0;
  let atCommandStart = atCommandStartInitial;

  while (i < n) {
    const ch = source[i];

    if (ch === ' ' || ch === '\t') {
      out += ch;
      i += 1;
      continue;
    }
    if (ch === '\n') {
      out += '\n';
      i += 1;
      atCommandStart = true;
      continue;
    }
    if (ch === '#') {
      let end = source.indexOf('\n', i);
      end = end === -1 ? n : end;
      out += `<span class="tok-comment">${escapeHtml(source.slice(i, end))}</span>`;
      i = end;
      atCommandStart = false;
      continue;
    }
    if (ch === "'") {
      let end = i + 1;
      while (end < n && source[end] !== "'") {
        end += 1;
      }
      const closed = end < n;
      if (closed) {
        end += 1;
      }
      out += `<span class="tok-string">${escapeHtml(source.slice(i, end))}</span>`;
      i = end;
      atCommandStart = false;
      continue;
    }
    if (ch === '"') {
      const result = renderDoubleQuoted(source, i);
      out += result.html;
      i = result.next;
      atCommandStart = false;
      continue;
    }
    if (ch === '$' && source[i + 1] === '(') {
      const closeIndex = findMatchingParen(source, i + 1);
      const end = closeIndex === -1 ? n : closeIndex;
      const inner = renderTokens(source.slice(i + 2, end), true);
      out += `<span class="tok-subst">$(${inner}${closeIndex === -1 ? '' : ')'}</span>`;
      i = closeIndex === -1 ? n : closeIndex + 1;
      atCommandStart = false;
      continue;
    }
    if (ch === '$') {
      const variable = renderVariable(source, i);
      out += variable.html;
      i = variable.next;
      atCommandStart = false;
      continue;
    }
    if (ch === '(') {
      out += escapeHtml(ch);
      i += 1;
      atCommandStart = true;
      continue;
    }
    if (ch === ';' || ch === '&' || ch === '|') {
      let end = i + 1;
      if ((ch === '&' && source[end] === '&') || (ch === '|' && source[end] === '|')) {
        end += 1;
      }
      out += escapeHtml(source.slice(i, end));
      i = end;
      atCommandStart = true;
      continue;
    }
    if (/[A-Za-z0-9_./~-]/.test(ch)) {
      let end = i;
      while (end < n && /[A-Za-z0-9_./~-]/.test(source[end])) {
        end += 1;
      }
      const word = source.slice(i, end);
      let cls: string | null = null;
      if (/^--?[A-Za-z]/.test(word)) {
        cls = 'tok-flag';
      } else if (BASH_KEYWORDS.has(word)) {
        cls = 'tok-keyword';
      } else if (/^[0-9][0-9.]*$/.test(word)) {
        cls = 'tok-number';
      } else if (atCommandStart) {
        cls = 'tok-command';
      }
      out += cls ? `<span class="${cls}">${escapeHtml(word)}</span>` : escapeHtml(word);
      i = end;
      atCommandStart = BASH_KEYWORDS.has(word);
      continue;
    }

    out += escapeHtml(ch);
    i += 1;
    atCommandStart = false;
  }

  return out;
}

/** Highlight one Bash snippet as HTML for insertion via `.innerHTML` into
 * a container that provides the `.tok-*` styles. */
export function highlightBashSyntax(source: string): string {
  return renderTokens(source, true);
}
