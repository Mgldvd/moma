// Documented custom-event contract used to coordinate independent
// components without any of them querying into another component's DOM,
// markup, or styles. Each event name is a public contract, the same way
// an element id used in an href="#id" anchor is: components on either
// side only need to agree on the name and the detail shape below.

/** Dispatched on `document` by Header when its mobile nav-toggle button is
 * activated. DocsNav listens for this and owns the actual open/close
 * state. */
export const NAV_TOGGLE_REQUEST = 'moma:navtoggle-request';

/** Dispatched on `document` by DocsNav whenever its open state changes, so
 * Header can reflect it on the triggering button's ARIA state. */
export const NAV_TOGGLE_STATE = 'moma:navtoggle-state';
export interface NavToggleStateDetail {
  open: boolean;
}

/** Dispatched on `document` by DocsNav's search field whenever the query
 * changes. ApiEntry and FunctionRow instances each decide their own
 * visibility from their own known search text. */
export const FILTER_EVENT = 'moma:filter';
export interface FilterDetail {
  query: string;
}

/** Dispatched (bubbling) by an ApiEntry/FunctionRow whenever its own
 * hidden state changes in response to a filter event, so ApiSection and
 * DocsNav can react without ever reading another component's DOM
 * directly. */
export const ENTRY_VISIBILITY_EVENT = 'moma:entry-visibility';
export interface EntryVisibilityDetail {
  id: string;
  visible: boolean;
}
