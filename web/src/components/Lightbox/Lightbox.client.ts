// Every [data-lightbox-trigger] on the page (one per ApiEntry screenshot,
// in document order) feeds one shared Lightbox instance. Arrow navigation
// walks that full list, wrapping around at either end, regardless of the
// current search filter - simpler than trying to keep it in sync with
// ApiEntry's own hidden state, and every screenshot is still reachable by
// scrolling to it directly either way.
const triggers = [...document.querySelectorAll<HTMLButtonElement>('[data-lightbox-trigger]')];

const lightbox = document.querySelector<HTMLElement>('.lightbox');
const image = lightbox?.querySelector<HTMLImageElement>('.lightbox__image');
const caption = lightbox?.querySelector<HTMLElement>('.lightbox__caption');
const closeButton = lightbox?.querySelector<HTMLButtonElement>('.lightbox__close');
const prevButton = lightbox?.querySelector<HTMLButtonElement>('.lightbox__nav--prev');
const nextButton = lightbox?.querySelector<HTMLButtonElement>('.lightbox__nav--next');

if (lightbox && image && caption && closeButton && prevButton && nextButton && triggers.length > 0) {
  const focusables = [prevButton, nextButton, closeButton];
  let currentIndex = 0;
  let lastFocused: HTMLElement | null = null;

  function show(index: number): void {
    currentIndex = (index + triggers.length) % triggers.length;
    const trigger = triggers[currentIndex];
    const sourceImage = trigger.querySelector('img');
    if (!sourceImage) {
      return;
    }
    image!.src = sourceImage.currentSrc || sourceImage.src;
    image!.alt = sourceImage.alt;
    caption!.textContent = trigger.dataset.lightboxCaption || sourceImage.alt;
    prevButton!.setAttribute(
      'aria-label',
      `Previous screenshot: ${triggers[(currentIndex - 1 + triggers.length) % triggers.length].dataset.lightboxCaption}`,
    );
    nextButton!.setAttribute(
      'aria-label',
      `Next screenshot: ${triggers[(currentIndex + 1) % triggers.length].dataset.lightboxCaption}`,
    );
  }

  function onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.preventDefault();
      close();
      return;
    }
    if (event.key === 'ArrowLeft') {
      event.preventDefault();
      show(currentIndex - 1);
      return;
    }
    if (event.key === 'ArrowRight') {
      event.preventDefault();
      show(currentIndex + 1);
      return;
    }
    if (event.key !== 'Tab') {
      return;
    }
    const first = focusables[0];
    const last = focusables[focusables.length - 1];
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  }

  function open(index: number): void {
    lastFocused = document.activeElement as HTMLElement | null;
    show(index);
    lightbox!.hidden = false;
    lightbox!.setAttribute('role', 'dialog');
    lightbox!.setAttribute('aria-modal', 'true');
    lightbox!.setAttribute('aria-label', 'Screenshot preview');
    document.body.style.overflow = 'hidden';
    requestAnimationFrame(() => {
      lightbox!.dataset.open = 'true';
    });
    document.addEventListener('keydown', onKeydown);
    closeButton!.focus();
  }

  function close(): void {
    lightbox!.dataset.open = 'false';
    lightbox!.removeAttribute('role');
    lightbox!.removeAttribute('aria-modal');
    document.body.style.overflow = '';
    document.removeEventListener('keydown', onKeydown);
    window.setTimeout(() => {
      if (lightbox!.dataset.open === 'false') {
        lightbox!.hidden = true;
      }
    }, 200);
    lastFocused?.focus();
  }

  triggers.forEach((trigger, index) => {
    trigger.addEventListener('click', () => open(index));
  });

  closeButton.addEventListener('click', () => close());
  prevButton.addEventListener('click', () => show(currentIndex - 1));
  nextButton.addEventListener('click', () => show(currentIndex + 1));

  lightbox.addEventListener('click', (event) => {
    if (event.target === lightbox) {
      close();
    }
  });
}
