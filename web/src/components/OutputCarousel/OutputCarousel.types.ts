export interface Props {
  /** Component name shown in the lightbox caption, e.g. "msg-simple". */
  name: string;
  /** One real screenshot per documented example, in the same order. Must
   * have at least 2 entries - ApiEntry only renders this component then. */
  frames: ImageMetadata[];
}
