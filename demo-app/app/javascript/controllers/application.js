import { Application } from "@hotwired/stimulus"
import { UltimateTurboModalController } from "ultimate_turbo_modal"

const application = Application.start()
application.register("modal", UltimateTurboModalController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Flatpickr — custom controller moves calendar inside <dialog> for modal compat
import FlatpickrController from "./flatpickr_controller"
application.register("flatpickr", FlatpickrController)

export { application }
