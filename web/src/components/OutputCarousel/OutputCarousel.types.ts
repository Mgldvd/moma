export interface Props {
  /** Component name shown in the lightbox caption, e.g. "msg-simple". */
  name: string;
  /** One real screenshot per catalog.yaml shot: the principal shot always
   * first, followed by any complementary shots in order. Must have at
   * least 2 entries - ApiEntry only renders this component then. */
  frames: ImageMetadata[];
}
