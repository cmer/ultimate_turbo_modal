# Body-Appended Widgets Inside Modals and Drawers

## The Problem

Many JavaScript libraries (datepickers, dropdown menus, rich text editors, color pickers, etc.) append their popup/overlay elements directly to `<body>` rather than inside the triggering element. Examples include Flatpickr, Tippy.js, Select2, and Floating UI-based components.

UTMR v3 uses the native `<dialog>` element opened with `showModal()`. When a dialog is open in this mode, the browser automatically marks **everything outside the dialog** as [inert](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/inert) — meaning those elements cannot receive focus, clicks, or any other user interaction. This is a browser-level behavior and cannot be overridden with CSS or JavaScript.

As a result, if a widget inside your modal triggers a popup that gets appended to `<body>` (outside the `<dialog>`), that popup will be inert and un-clickable.

**Note:** The `allowed_click_outside_selector` configuration option does not solve this problem. It only prevents the modal from *dismissing* when clicking matching elements — it cannot make inert elements interactive again.

## Solutions

### Option 1: Configure the widget to render inside the dialog

Most popup libraries accept a `container` or `appendTo` option. Set it to the dialog element or a container inside it.

**Flatpickr example:**

The UTMR demo app uses [stimulus-flatpickr](https://www.npmjs.com/package/stimulus-flatpickr) with a custom controller that moves the calendar inside the dialog after initialization. See the full implementation at [`demo-app/app/javascript/controllers/flatpickr_controller.js`](../demo-app/app/javascript/controllers/flatpickr_controller.js):

```javascript
import Flatpickr from "stimulus-flatpickr"

export default class extends Flatpickr {
  connect() {
    super.connect()

    const dialog = this.element.closest("dialog")
    if (dialog && this.fp?.calendarContainer) {
      dialog.appendChild(this.fp.calendarContainer)
    }
  }
}
```

If you're using Flatpickr directly (without the Stimulus wrapper), you can use the `appendTo` option instead:

```javascript
import flatpickr from "flatpickr"

const dialog = element.closest("dialog")
flatpickr(element, {
  appendTo: dialog || undefined,
})
```

**Tippy.js example:**

```javascript
tippy(element, {
  appendTo: element.closest("dialog") || document.body,
})
```

**Floating UI example:**

When using Floating UI directly, render the floating element inside the dialog rather than appending it to `<body>`.

### Option 2: Move elements into the dialog with a MutationObserver

If you cannot configure the library's append target, you can observe `<body>` for newly added elements and relocate them into the dialog automatically.

```javascript
// Stimulus controller that relocates a widget's popups into the dialog
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { selector: String } // e.g. ".flatpickr-calendar"

  connect() {
    this.dialog = this.element.closest("dialog")
    if (!this.dialog) return

    this.relocated = []
    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType !== Node.ELEMENT_NODE) continue
          if (this.dialog.contains(node)) continue
          if (node.matches(this.selectorValue)) {
            this.#relocate(node)
          }
        }
      }
    })

    this.observer.observe(document.body, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
    for (const { element, placeholder } of this.relocated) {
      placeholder.parentNode?.insertBefore(element, placeholder)
      placeholder.remove()
    }
    this.relocated = []
  }

  #relocate(element) {
    const placeholder = document.createComment("utmr-relocated")
    element.parentNode.insertBefore(placeholder, element)
    this.dialog.appendChild(element)
    this.relocated.push({ element, placeholder })
  }
}
```

Usage in your view:

```erb
<div data-controller="relocate-widget" data-relocate-widget-selector-value=".flatpickr-calendar">
  <input data-controller="flatpickr" type="text">
</div>
```

### Option 3: Use `<dialog>`-aware libraries

Some newer UI libraries are aware of the `<dialog>` top layer and handle this correctly out of the box. When choosing new dependencies, check whether they support rendering inside `<dialog>` elements opened with `showModal()`.

## Background

This is not specific to UTMR — it affects **any** use of the native `<dialog>` element with `showModal()`. The [HTML spec](https://html.spec.whatwg.org/multipage/interactive-elements.html#dom-dialog-showmodal) requires that content outside the top-layer dialog be made inert. This is the same mechanism that provides native focus trapping and accessibility benefits.
