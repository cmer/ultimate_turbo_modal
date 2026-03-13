import { Controller } from '@hotwired/stimulus';

// This placeholder will be replaced by rollup
const PACKAGE_VERSION = '__PACKAGE_VERSION__';

export default class extends Controller {
  static targets = ["container", "content"]
  static values = {
    advanceUrl: String,
    allowedClickOutsideSelector: String
  }

  connect() {
    this.#checkVersions();
    this.hidingModal = false;
    this.showModal();
    this.turboFrame = this.element.closest('turbo-frame');

    // hide modal when back button is pressed
    this.popstateHandler = () => {
      if (this.#hasHistoryAdvanced()) this.#resetModalElement();
    };
    window.addEventListener('popstate', this.popstateHandler);

    // Remove the dialog from Turbo's page cache to prevent stale state
    this.beforeCacheHandler = () => {
      this.containerTarget.remove();
    };
    document.addEventListener('turbo:before-cache', this.beforeCacheHandler);

    window.modal = this;
  }

  disconnect() {
    this.#cancelDrawerEnter();
    clearTimeout(this.closeTimeout);
    window.removeEventListener('popstate', this.popstateHandler);
    document.removeEventListener('turbo:before-cache', this.beforeCacheHandler);
    window.modal = undefined;
  }

  showModal() {
    // Clean up stale state that may persist from Turbo's page cache
    this.containerTarget.removeAttribute('data-closing');
    this.containerTarget.removeAttribute('data-enter-ready');
    this.containerTarget.removeAttribute('data-entered');
    if (this.containerTarget.open) this.containerTarget.close();
    const scrollX = window.scrollX;
    const scrollY = window.scrollY;
    this.containerTarget.showModal();
    window.scrollTo(scrollX, scrollY);
    if (this.#isDrawer()) this.#queueDrawerEnter();

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

    if (this.#hasHistoryAdvanced()) {
      // history.back() will fire popstate, which triggers #resetModalElement
      // via the popstateHandler. Don't call it directly to avoid double cleanup.
      history.back();
    } else {
      this.#resetModalElement();
    }
  }

  hide() {
    this.hideModal();
  }

  close() {
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

  // Intercept native dialog cancel event (ESC key)
  // action: "cancel->modal#cancelEvent"
  cancelEvent(e) {
    e.preventDefault(); // Prevent native dialog.close()
    this.hideModal();   // Use our close flow with events + animation
  }

  // Handle clicks outside the modal content (backdrop area)
  // action: "click->modal#dialogClicked"
  dialogClicked(e) {
    // The dialog is full-screen, so clicks on the area outside the modal card
    // land on the dialog or its inner wrapper (#modal-inner), not on ::backdrop.
    // Dismiss if the click is outside the content (modal card).
    if (this.contentTarget.contains(e.target)) return;
    if (this.#isAllowedOutsideClick(e.target)) return;
    this.hideModal();
  }

  #isAllowedOutsideClick(target) {
    if (!this.allowedClickOutsideSelectorValue) return false;
    return target.closest(this.allowedClickOutsideSelectorValue) !== null;
  }

  #resetModalElement() {
    const dialog = this.containerTarget;
    dialog.setAttribute('data-closing', '');
    dialog.setAttribute('data-enter-ready', '');
    dialog.removeAttribute('data-entered');
    this.#cancelDrawerEnter();

    const closeEventName = this.#isDrawer() ? 'transitionend' : 'animationend';
    const closeEventTarget = this.#isDrawer() ? this.contentTarget : dialog;
    const closeTimeoutMs = this.#isDrawer() ? 750 : 300;

    let cleaned = false;
    const cleanup = () => {
      if (cleaned) return;
      cleaned = true;
      clearTimeout(this.closeTimeout);
      const frame = this.turboFrame;
      dialog.close();
      frame.removeAttribute("src");
      dialog.remove();
      this.#resetHistoryAdvanced();
      frame.dispatchEvent(new Event('modal:closed', { cancelable: false }));
    };

    closeEventTarget.addEventListener(closeEventName, cleanup, { once: true });
    // Fallback if no animation defined (custom flavor with empty classes)
    this.closeTimeout = setTimeout(cleanup, closeTimeoutMs);
  }

  #isDrawer() {
    return this.containerTarget.dataset.drawer !== undefined
  }

  #queueDrawerEnter() {
    this.#cancelDrawerEnter();

    this.drawerEnterFrame = requestAnimationFrame(() => {
      if (!this.containerTarget.isConnected || this.containerTarget.hasAttribute('data-closing')) return;
      this.containerTarget.setAttribute('data-enter-ready', '');

      this.drawerEnterFrame = requestAnimationFrame(() => {
        if (!this.containerTarget.isConnected || this.containerTarget.hasAttribute('data-closing')) return;
        this.containerTarget.setAttribute('data-entered', '');
        this.drawerEnterFrame = null;
      });
    });
  }

  #cancelDrawerEnter() {
    if (!this.drawerEnterFrame) return;
    cancelAnimationFrame(this.drawerEnterFrame);
    this.drawerEnterFrame = null;
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

  // Normalize a version string so Ruby gem format ("3.0.0.alpha") and
  // npm/semver format ("3.0.0-alpha.0") can be compared reliably.
  #normalizeVersion(v) {
    return v
      .replace(/\.([a-z]+)(?:\.(\d+))?$/, '-$1') // "3.0.0.alpha" → "3.0.0-alpha"
      .replace(/-([a-z]+)\.\d+$/, '-$1');          // "3.0.0-alpha.0" → "3.0.0-alpha"
  }

  #checkVersions() {
    const gemVersion = this.element.dataset.utmrVersion;

    if (!gemVersion) {
      // If the attribute isn't set (e.g., in production), skip the check.
      return;
    }

    if (this.#normalizeVersion(gemVersion) !== this.#normalizeVersion(PACKAGE_VERSION)) {
      console.warn(
        `[UltimateTurboModal] Version Mismatch!\n\nGem Version: ${gemVersion}\nJS Version:  ${PACKAGE_VERSION}\n\nPlease ensure both the 'ultimate_turbo_modal' gem and the 'ultimate-turbo-modal' npm package are updated to the same version.\nElement:`, this.element
      );
    }
  }
}
