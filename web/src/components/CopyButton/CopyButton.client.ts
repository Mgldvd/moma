// Wires up every CopyButton instance on the page. This module is imported
// once per <CopyButton> usage, but the browser's module cache only
// executes it once, so it safely supports any number of instances.
export {};

function announceCopied(button: HTMLButtonElement): void {
  window.clearTimeout(Number(button.dataset.copyResetTimer));
  button.textContent = 'Copied';
  button.dataset.copied = 'true';
  button.setAttribute('aria-label', 'Copied to clipboard');
  button.dataset.copyResetTimer = String(
    window.setTimeout(() => {
      button.textContent = 'Copy';
      delete button.dataset.copied;
      button.setAttribute('aria-label', button.dataset.copyLabel || 'Copy command to clipboard');
    }, 1500),
  );
}

function legacyCopy(text: string, button: HTMLButtonElement): void {
  const textarea = document.createElement('textarea');
  textarea.value = text;
  textarea.setAttribute('readonly', '');
  textarea.style.position = 'fixed';
  textarea.style.left = '-9999px';
  document.body.append(textarea);
  textarea.select();
  try {
    if (document.execCommand('copy')) {
      announceCopied(button);
    }
  } catch {
    // Copying is unsupported in this browser; leave the button as-is.
  } finally {
    textarea.remove();
  }
}

function copyTextToClipboard(text: string, button: HTMLButtonElement): void {
  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(text).then(
      () => announceCopied(button),
      () => legacyCopy(text, button),
    );
  } else {
    legacyCopy(text, button);
  }
}

document.querySelectorAll<HTMLButtonElement>('.copy-btn[data-copy-text]').forEach((button) => {
  if (button.dataset.copyReady === 'true') {
    return;
  }
  button.dataset.copyReady = 'true';
  button.dataset.copyLabel = button.getAttribute('aria-label') || 'Copy command to clipboard';
  button.addEventListener('click', () => {
    copyTextToClipboard(button.dataset.copyText || '', button);
  });
});
