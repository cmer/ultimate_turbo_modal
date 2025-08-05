import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Flatpickr
import Flatpickr from "stimulus-flatpickr"
application.register('flatpickr', Flatpickr)

export { application }
