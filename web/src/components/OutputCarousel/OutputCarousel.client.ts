import { collectOutputFrames, showOutputFrame } from '../../utils/outputFrames';

document.querySelectorAll<HTMLElement>('.output-carousel').forEach((carousel) => {
  const thumbnails = [...carousel.querySelectorAll<HTMLButtonElement>('.output-carousel__thumbnail')];
  const frames = collectOutputFrames(carousel);

  if (thumbnails.length === 0 || frames.length < 2) {
    return;
  }

  thumbnails.forEach((thumbnail, thumbnailIndex) => {
    thumbnail.addEventListener('click', () => showOutputFrame(carousel, frames, thumbnailIndex));
  });
});
