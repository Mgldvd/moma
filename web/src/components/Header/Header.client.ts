import { NAV_TOGGLE_REQUEST, NAV_TOGGLE_STATE, type NavToggleStateDetail } from '../../utils/events';

const header = document.querySelector<HTMLElement>('.topbar');
if (header) {
  const navToggle = header.querySelector<HTMLButtonElement>('.nav-toggle');

  navToggle?.addEventListener('click', () => {
    document.dispatchEvent(new CustomEvent(NAV_TOGGLE_REQUEST));
  });

  document.addEventListener(NAV_TOGGLE_STATE, (event) => {
    const { open } = (event as CustomEvent<NavToggleStateDetail>).detail;
    navToggle?.setAttribute('aria-expanded', String(open));
  });
}
