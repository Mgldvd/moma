// Shared by OutputCarousel.client (the inline per-component carousel) and
// Lightbox.client (its thumbnail strip) - both read and update the same
// .output-carousel markup, so the logic for doing that lives here once
// rather than drifting between two independent client scripts.

export interface OutputFrame {
  src: string;
  srcset: string;
  alt: string;
}

// Every frame - real per-example screenshots, Astro-optimized at build
// time - lives in the carousel's <template> (see OutputCarousel.astro),
// which never changes regardless of which one the live <img> currently
// shows. Reading from here instead of the live <img> means callers never
// have to special-case "whichever frame happens to be showing right now."
export function collectOutputFrames(carousel: Element): OutputFrame[] {
  const template = carousel.querySelector<HTMLTemplateElement>('.output-carousel__frame-data');
  if (!template) {
    return [];
  }
  return [...template.content.querySelectorAll('img')].map((frame) => ({
    src: frame.src,
    srcset: frame.srcset,
    alt: frame.alt,
  }));
}

// Single source of truth for "show frame N of this carousel": updates the
// live <img>, the carousel's own thumbnail strip, its Lightbox trigger's
// caption/label, and the carousel's own `data-current-frame` bookkeeping,
// all together - so the inline carousel's prev/next/thumbnails and the
// Lightbox's own thumbnail strip can never leave each other out of sync.
export function showOutputFrame(carousel: HTMLElement, frames: OutputFrame[], index: number): void {
  if (frames.length === 0) {
    return;
  }
  const wrapped = ((index % frames.length) + frames.length) % frames.length;
  const frame = frames[wrapped];
  carousel.dataset.currentFrame = String(wrapped);

  const image = carousel.querySelector<HTMLImageElement>('.output-carousel__image');
  if (image) {
    image.src = frame.src;
    image.srcset = frame.srcset;
    image.alt = frame.alt;
  }

  const trigger = carousel.querySelector<HTMLButtonElement>('.output-carousel__trigger');
  if (trigger) {
    // Stashed once so repeated calls always suffix the same original
    // caption instead of compounding onto an already-suffixed one.
    const baseCaption = trigger.dataset.outputCaption ?? trigger.dataset.lightboxCaption ?? '';
    trigger.dataset.outputCaption = baseCaption;
    trigger.dataset.lightboxCaption =
      frames.length > 1 ? `${baseCaption} — example ${wrapped + 1} of ${frames.length}` : baseCaption;
    trigger.setAttribute('aria-label', `View ${frame.alt}, full-size`);
  }

  const thumbnails = [...carousel.querySelectorAll<HTMLButtonElement>('.output-carousel__thumbnail')];
  thumbnails.forEach((thumbnail, thumbnailIndex) => {
    thumbnail.setAttribute('aria-current', thumbnailIndex === wrapped ? 'true' : 'false');
  });
}
