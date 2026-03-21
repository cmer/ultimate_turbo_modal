import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toast"]

  connect() {
    // Slide each toast in with a stagger
    this.toastTargets.forEach((toast, index) => {
      setTimeout(() => {
        toast.classList.remove("translate-x-[120%]", "opacity-0")
        toast.classList.add("translate-x-0", "opacity-100")
      }, index * 100)
    })

    // Auto-dismiss after 4 seconds
    this.dismissTimeout = setTimeout(() => this.dismissAll(), 4000)
  }

  disconnect() {
    if (this.dismissTimeout) clearTimeout(this.dismissTimeout)
  }

  dismissAll() {
    this.toastTargets.forEach((toast, index) => {
      setTimeout(() => {
        toast.classList.remove("translate-x-0", "opacity-100")
        toast.classList.add("translate-x-[120%]", "opacity-0")
      }, index * 80)
    })

    // Remove from DOM after animation completes
    setTimeout(() => this.element.remove(), this.toastTargets.length * 80 + 300)
  }
}
