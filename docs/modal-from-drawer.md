# Opening a Modal from a Drawer

Ultimate Turbo Modal supports opening a regular modal that stacks visually on top of an already-open drawer. This document covers how it works under the hood, what edge cases to expect, and how to test it.

## Quick start

Inside any drawer, link to a modal action with `data-turbo-frame="drawer-modal"`:

```erb
<%= drawer(title: "Notifications") do %>
  <%= link_to "Edit preferences",
        edit_preferences_path,
        data: { turbo_frame: "drawer-modal" } %>
<% end %>
```

The target action renders with the standard `modal()` helper — no special API.

```erb
<%= modal(title: "Notification preferences") do %>
  <%= form_with url: preferences_path, method: :post do %>
    …
  <% end %>
<% end %>
```

That's it. No layout change, no opt-in.

## How it works

Drawers always render an empty `<turbo-frame id="drawer-modal">` inside their DOM, alongside the visible drawer panel. When a link inside the drawer targets that frame, Turbo loads the response into it — and because the response is rendered with `modal()`, it's a `<dialog>` that gets pushed onto the browser's native top layer above the drawer.

Internally:

- The stacked dialog uses a different element id (`modal-container-stacked`) so it doesn't collide with the primary modal/drawer (`modal-container`) for cleanup, scroll-lock, and CSS purposes.
- Every inner element (`modal-content`, `modal-header`, etc.) is suffixed with `-stacked` for the same reason.
- A module-level dialog stack tracks every open dialog. `window.modal` is always re-pointed at the topmost one, so existing single-modal code continues to work unchanged.

## Lifecycle

```
1. Drawer opens (turbo-frame#modal)
   ├─ <dialog id="modal-container">
   └─ contains an empty <turbo-frame id="drawer-modal">

2. Link inside drawer with data-turbo-frame="drawer-modal" is clicked
   ├─ Turbo loads response into the empty frame
   └─ Response is rendered by modal() with stacked ids

3. Stacked modal connects
   ├─ <dialog id="modal-container-stacked"> appears on top of drawer
   ├─ window.modal points to the stacked modal
   └─ Drawer's controller is still in dialogStack

4. User dismisses stacked modal (ESC, close button, click-outside, server)
   ├─ Inner closes with animation
   ├─ window.modal reverts to drawer's controller
   └─ Drawer remains visible

5. User dismisses drawer
   └─ Standard drawer close path
```

## Edge cases

### ESC key

Native `<dialog>` elements form a top-layer stack. Pressing ESC dispatches the `cancel` event to the topmost dialog only. So one ESC closes the inner modal; another ESC closes the drawer.

### Click outside

Each dialog's controller checks whether the click was inside its own content card. The inner modal's content is its modal card, so a click anywhere outside that card (including on the visible drawer behind) is treated as an outside-click and closes the inner modal.

### Form submission inside the inner modal

Two redirect cases:

- **Same-page redirect** (the form action redirects back to the page the drawer was opened from): the inner modal closes smoothly with its animation, the URL is updated via `history.replaceState`, and the drawer stays open. The page body is *not* morphed — that would clobber the drawer's DOM.
- **Different-page redirect**: every open dialog (the inner modal and the drawer) is closed in sequence, top-down, then `Turbo.visit()` navigates to the new page.

If the form returns a Turbo Stream response, it's processed normally. `turbo_stream.modal(:close)` operates on `window.modal`, which is the inner modal.

### Closing the drawer while the modal is open

If the drawer is closed (e.g. from a Turbo Stream or a programmatic call) while the inner modal is still open, the modal disappears with the drawer. There is no graceful animation in this case — the inner modal lives inside the drawer's DOM tree, and removing the drawer takes it with it.

If you need a graceful close, dismiss the inner modal first (via `window.modal.hide()` or `turbo_stream.modal(:close)`), then close the drawer.

### Browser back

Neither drawers nor stacked modals push to browser history (`advance: false` is forced for both). Pressing the browser back button navigates the underlying page; both dialogs are removed cleanly via the `turbo:before-cache` handler.

### Backdrop appearance

Each open dialog draws its own `::backdrop`. With both at `overlay: true`, the drawer area appears slightly darker while the modal is open (two semi-transparent overlays stacked). If you don't want the doubled darkness, pass `overlay: false` to the inner modal:

```erb
<%= modal(title: "Edit preferences", overlay: false) do %>
  …
<% end %>
```

## Constraints

- **Modal from drawer only.** You can't open a drawer from inside a modal, and you can't open another modal from inside a modal. The `drawer-modal` frame is only rendered inside drawers, so any link with `data-turbo-frame="drawer-modal"` from outside a drawer falls through to a normal full-page navigation.
- **Depth = 2.** Stacked modals don't render their own nested `drawer-modal` frame. Two levels (drawer + modal) is the maximum.
- **`advance` is forced false.** Stacked modals never push history regardless of the `advance:` option.

## Testing

The demo app includes a showcase tile (`Drawer with nested modal`) and a developer testing page at `/testing/drawers/nested_modal_host` that exercises the edge cases above.
