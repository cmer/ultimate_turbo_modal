import Flatpickr from "stimulus-flatpickr"

// Custom Flatpickr controller that moves the calendar inside a <dialog>
// when opened within a modal. This is necessary because showModal() makes
// all elements outside the dialog inert, including body-appended popups.
export default class extends Flatpickr {
  connect() {
    super.connect()

    const dialog = this.element.closest("dialog")
    if (dialog && this.fp?.calendarContainer) {
      dialog.appendChild(this.fp.calendarContainer)
    }
  }
}
