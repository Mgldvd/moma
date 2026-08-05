import { collectOutputFrames, showOutputFrame } from '../../utils/outputFrames';

// Every [data-lightbox-trigger] on the page (one per ApiEntry screenshot,
// in document order) feeds one shared Lightbox instance. Arrow navigation
// walks that full list, wrapping around at either end, regardless of the
// current search filter - simpler than trying to keep it in sync with
// ApiEntry's own hidden state, and every screenshot is still reachable by
// scrolling to it directly either way. This is navigation *between*
// components; a trigger belonging to an OutputCarousel additionally gets
// its own thumbnail strip below the image, for navigating *within* that
// one component's own examples without leaving the lightbox.
const triggers = [...document.querySelectorAll<HTMLButtonElement>('[data-lightbox-trigger]')];

const lightbox = document.querySelector<HTMLElement>('.lightbox');
const image = lightbox?.querySelector<HTMLImageElement>('.lightbox__image');
const caption = lightbox?.querySelector<HTMLElement>('.lightbox__caption');
const thumbnails = lightbox?.querySelector<HTMLElement>('.lightbox__thumbnails');
const closeButton = lightbox?.querySelector<HTMLButtonElement>('.lightbox__close');
const prevButton = lightbox?.querySelector<HTMLButtonElement>('.lightbox__nav--prev');
const nextButton = lightbox?.querySelector<HTMLButtonElement>('.lightbox__nav--next');

if (lightbox && image && caption && thumbnails && closeButton && prevButton && nextButton && triggers.length > 0) {
  let currentIndex = 0;
  let lastFocused: HTMLElement | null = null;

  // Tab-trap cycle, recomputed on every keypress rather than once: the
  // thumbnail strip's own button count changes every time show() runs.
  function focusables(): HTMLElement[] {
    const thumbButtons = [...thumbnails!.querySelectorAll<HTMLButtonElement>('.lightbox__thumbnail')];
    return [prevButton!, nextButton!, ...thumbButtons, closeButton!];
  }

  function renderThumbnails(trigger: HTMLButtonElement): void {
    const carousel = trigger.closest<HTMLElement>('.output-carousel');
    const frames = carousel ? collectOutputFrames(carousel) : [];
    thumbnails!.replaceChildren();
    thumbnails!.hidden = !carousel || frames.length < 2;
    if (!carousel || frames.length < 2) {
      return;
    }
    const activeIndex = Number(carousel.dataset.currentFrame || 0);
    frames.forEach((frame, frameIndex) => {
      const thumb = document.createElement('button');
      thumb.type = 'button';
      thumb.className = 'lightbox__thumbnail';
      thumb.setAttribute('aria-current', frameIndex === activeIndex ? 'true' : 'false');
      thumb.setAttribute('aria-label', `Show example ${frameIndex + 1} of ${frames.length}`);
      const thumbImage = document.createElement('img');
      thumbImage.src = frame.src;
      thumbImage.srcset = frame.srcset;
      thumbImage.alt = '';
      thumbImage.loading = 'lazy';
      thumb.append(thumbImage);
      thumb.addEventListener('click', () => {
        showOutputFrame(carousel, frames, frameIndex);
        image!.src = frame.src;
        image!.alt = frame.alt;
        caption!.textContent = trigger.dataset.lightboxCaption || frame.alt;
        renderThumbnails(trigger);
      });
      thumbnails!.append(thumb);
    });
  }

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
    renderThumbnails(trigger);
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
    const cycle = focusables();
    const first = cycle[0];
    const last = cycle[cycle.length - 1];
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
