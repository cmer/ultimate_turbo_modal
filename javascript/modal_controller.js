import { Controller } from '@hotwired/stimulus';
import { enter, leave } from 'el-transition';
import { createFocusTrap } from 'focus-trap';

// This placeholder will be replaced by rollup
const PACKAGE_VERSION = '__PACKAGE_VERSION__';

export default class extends Controller {
  static targets = ["container", "content"]
  static values = {
    advanceUrl: String,
    allowedClickOutsideSelector: String,
    focusTrap: { type: Boolean, default: true }
  }

  connect() {
    let _this = this;

    this.#checkVersions();

    // Initialize focus trap instance variable
    this.focusTrapInstance = null;

    this.showModal();

    this.turboFrame = this.element.closest('turbo-frame');

    // hide modal when back button is pressed
    window.addEventListener('popstate', function (event) {
      if (_this.#hasHistoryAdvanced()) _this.#resetModalElement();
    });

    window.modal = this;
  }

  disconnect() {
    // Clean up focus trap if it exists
    if (this.focusTrapInstance) {
      this.#deactivateFocusTrap();
    }
    window.modal = undefined;
  }

  showModal() {
    enter(this.containerTarget).then(() => {
      // Activate focus trap after the modal transition is complete
      if (this.focusTrapValue) {
        this.#activateFocusTrap();
      }
    });

    if (this.advanceUrlValue && !this.#hasHistoryAdvanced()) {
      this.#setHistoryAdvanced();
      history.pushState({}, "", this.advanceUrlValue);
    }
  }

  // if we advanced history, go back, which will trigger
  // hiding the model. Otherwise, hide the modal directly.
  hideModal() {
    // Prevent multiple calls to hideModal.
    // Sometimes some events are double-triggered.
    if (this.hidingModal) return
    this.hidingModal = true;

    let event = new Event('modal:closing', { cancelable: true });
    this.turboFrame.dispatchEvent(event);
    if (event.defaultPrevented) {
      this.hidingModal = false;
      return
    }

    // Deactivate focus trap only after confirming modal will close
    if (this.focusTrapInstance) {
      this.#deactivateFocusTrap();
    }

    this.#resetModalElement();

    event = new Event('modal:closed', { cancelable: false });
    this.turboFrame.dispatchEvent(event);

    if (this.#hasHistoryAdvanced())
      history.back();
  }

  hide() {
    this.hideModal();
  }

  refreshPage() {
    window.Turbo.visit(window.location.href, { action: "replace" });
  }

  // hide modal on successful form submission
  // action: "turbo:submit-end->modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) this.hideModal();
  }

  // hide modal when clicking ESC
  // action: "keyup@window->modal#closeWithKeyboard"
  closeWithKeyboard(e) {
    if (e.code == "Escape") this.hideModal();
  }

  // hide modal when clicking outside of modal
  // action: "click@window->modal#outsideModalClicked"
  outsideModalClicked(e) {
    let clickedInsideModal = !document.contains(e.target) || this.contentTarget.contains(e.target) || this.contentTarget == e.target;
    let clickedAllowedSelector = this.allowedClickOutsideSelectorValue && this.allowedClickOutsideSelectorValue !== '' && e.target.closest(this.allowedClickOutsideSelectorValue) != null;

    if (!clickedInsideModal && !clickedAllowedSelector)
      this.hideModal();
  }

  #resetModalElement() {
    leave(this.containerTarget).then(() => {
      this.turboFrame.removeAttribute("src");
      this.containerTarget.remove();
      this.#resetHistoryAdvanced();
    });
  }

  #hasHistoryAdvanced() {
    return document.body.getAttribute("data-turbo-modal-history-advanced") == "true"
  }

  #setHistoryAdvanced() {
    return document.body.setAttribute("data-turbo-modal-history-advanced", "true")
  }

  #resetHistoryAdvanced() {
    document.body.removeAttribute("data-turbo-modal-history-advanced");
  }

  #checkVersions() {
    const gemVersion = this.element.dataset.utmrVersion;

    if (!gemVersion) {
      // If the attribute isn't set (e.g., in production), skip the check.
      return;
    }

    if (gemVersion !== PACKAGE_VERSION) {
      console.warn(
        `[UltimateTurboModal] Version Mismatch!\n\nGem Version: ${gemVersion}\nJS Version:  ${PACKAGE_VERSION}\n\nPlease ensure both the 'ultimate_turbo_modal' gem and the 'ultimate-turbo-modal' npm package are updated to the same version.\nElement:`, this.element
      );
    }
  }

  #activateFocusTrap() {
    try {
      // Create focus trap if it doesn't exist
      if (!this.focusTrapInstance) {
        this.focusTrapInstance = createFocusTrap(this.contentTarget, {
          allowOutsideClick: true,
          escapeDeactivates: false, // Let our ESC handler manage this
          fallbackFocus: this.contentTarget,
          returnFocusOnDeactivate: true,
          clickOutsideDeactivates: false, // Let our click outside handler manage this
          preventScroll: false,
          initialFocus: () => {
            // Try to focus the first focusable element, or the modal itself
            const firstFocusable = this.contentTarget.querySelector(
              'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
            );
            return firstFocusable || this.contentTarget;
          }
        });
      }

      // Activate the trap
      this.focusTrapInstance.activate();
    } catch (error) {
      console.error('[UltimateTurboModal] Failed to activate focus trap:', error);
      // Don't break the modal if focus trap fails
      this.focusTrapInstance = null;
    }
  }

  #deactivateFocusTrap() {
    try {
      if (this.focusTrapInstance && this.focusTrapInstance.active) {
        this.focusTrapInstance.deactivate();
      }
    } catch (error) {
      console.error('[UltimateTurboModal] Failed to deactivate focus trap:', error);
    } finally {
      this.focusTrapInstance = null;
    }
  }
}
