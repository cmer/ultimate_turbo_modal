import { Controller } from '@hotwired/stimulus';

// This placeholder will be replaced by rollup
const PACKAGE_VERSION = '__PACKAGE_VERSION__';

// Stack of currently-connected modal/drawer controllers, in open order.
// The topmost (last) entry is exposed as window.modal so existing
// `window.modal.hide()` and `Turbo.StreamActions.modal` calls always operate
// on the dialog the user is most directly interacting with.
const dialogStack = [];

// Scrollbar gutter compensation: while a dialog is open the page scrollbar is
// hidden by `html:has(dialog[open]) { overflow: hidden }`, which would shift
// the page contents to the right. We reserve that space with `padding-right`
// on <html>, and shift right-anchored fixed elements (top-right toolbars,
// floating action buttons, etc.) so they stay visually pinned. The first
// dialog measures and applies; the last one to close restores everything.
const scrollLockOwners = new Set();
let scrollbarPaddingApplied = false;
let savedPaddingRight = '';
let compensatedFixedElements = [];

export default class extends Controller {
  static targets = ["container", "content"]
  static values = {
    advanceUrl: String,
    allowedClickOutsideSelector: String
  }

  connect() {
    this.#checkVersions();
    this.#cleanupStaleDialogs();
    this.turboFrame = this.element.closest('turbo-frame');
    this.hidingModal = this.containerTarget.hasAttribute('data-closing');
    this.originalUrl = window.location.href;

    if (!dialogStack.includes(this)) dialogStack.push(this);

    // Same-page morphs can briefly disconnect/reconnect the controller while the
    // dialog is already open. Replaying showModal() there re-triggers the enter
    // animation and causes a visible reopen during close.
    if (this.hidingModal) {
      this.#resumeClosing();
    } else if (!this.containerTarget.open) {
      this.showModal();
    }

    // When the user presses the browser back button, Turbo handles the
    // navigation (restoring the previous page). We just need to clean up
    // the dialog element — no animation needed since the page is changing.
    this.popstateHandler = () => {
      if (this.#hasHistoryAdvanced()) {
        this.#resetHistoryAdvanced();
        this.#immediateCleanup();
      }
    };
    window.addEventListener('popstate', this.popstateHandler);

    // Remove the dialog from Turbo's page cache to prevent stale state
    this.beforeCacheHandler = () => {
      this.containerTarget.remove();
      this.#releaseScrollbarCompensation();
    };
    document.addEventListener('turbo:before-cache', this.beforeCacheHandler);

    window.modal = dialogStack[dialogStack.length - 1];
  }

  disconnect() {
    this.#cancelEnter();
    this.#cancelResumeClosing();
    this.#cancelCloseCleanup();
    window.removeEventListener('popstate', this.popstateHandler);
    document.removeEventListener('turbo:before-cache', this.beforeCacheHandler);

    const idx = dialogStack.indexOf(this);
    if (idx !== -1) dialogStack.splice(idx, 1);
    window.modal = dialogStack[dialogStack.length - 1];
  }

  showModal() {
    // Clean up stale state that may persist from Turbo's page cache
    this.containerTarget.removeAttribute('data-closing');
    this.containerTarget.removeAttribute('data-enter-ready');
    this.containerTarget.removeAttribute('data-entered');
    if (this.containerTarget.open) this.containerTarget.close();
    const scrollX = window.scrollX;
    const scrollY = window.scrollY;
    this.#applyScrollbarCompensation();
    this.containerTarget.showModal();
    window.scrollTo(scrollX, scrollY);
    this.#queueEnter();

    if (this.advanceUrlValue && !this.#hasHistoryAdvanced()) {
      this.#setHistoryAdvanced();
      history.pushState({}, "", this.advanceUrlValue);
    }
  }

  // Animate the close transition, then clean up.
  // history.back() is deferred to after the animation so Turbo doesn't
  // replace the page before the animation finishes.
  hideModal({ skipHistoryBack = false } = {}) {
    // Prevent multiple calls to hideModal.
    // Sometimes some events are double-triggered.
    if (this.hidingModal) return false
    this.hidingModal = true;

    let event = new Event('modal:closing', { cancelable: true });
    this.turboFrame.dispatchEvent(event);
    if (event.defaultPrevented) {
      this.hidingModal = false;
      return false
    }

    this._skipHistoryBack = skipHistoryBack;
    this.#resetModalElement();
  }

  hideModalWithPromise(options = {}) {
    return new Promise((resolve) => {
      const frame = this.turboFrame;
      const handler = () => {
        frame.removeEventListener('modal:closed', handler);
        resolve();
      };
      frame.addEventListener('modal:closed', handler);
      if (this.hideModal(options) === false) {
        frame.removeEventListener('modal:closed', handler);
        resolve();
      }
    });
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
    if (e.detail.success) {
      const response = e.detail.fetchResponse?.response;
      if (response?.redirected) {
        this._pendingRedirectUrl = response.url;
        return;
      }
      this.hideModal();
    }
  }

  // Intercept native dialog cancel event (ESC key)
  // action: "cancel->modal#cancelEvent"
  cancelEvent(e) {
    e.preventDefault(); // Prevent native dialog.close()
    this.hideModal();   // Use our close flow with events + animation
  }

  // Track where a press started so we can avoid dismissing when the press
  // began inside content but the click resolved on the dialog (e.g. a
  // body-appended popup opened between mousedown and mouseup, shifting the
  // mouseup target — the browser then fires `click` on the common ancestor,
  // which is the dialog itself).
  // action: "mousedown->modal#dialogMousedown"
  dialogMousedown(e) {
    this._mousedownInsideContent =
      this.hasContentTarget && this.contentTarget.contains(e.target);
  }

  // Handle clicks outside the modal content (backdrop area)
  // action: "click->modal#dialogClicked"
  dialogClicked(e) {
    // The dialog is full-screen, so clicks on the area outside the modal card
    // land on the dialog or its inner wrapper (#modal-inner), not on ::backdrop.
    // Dismiss if the click is outside the content (modal card).
    if (!this.hasContentTarget) return;
    const pressedInside = this._mousedownInsideContent;
    this._mousedownInsideContent = false;
    if (this.contentTarget.contains(e.target)) return;
    if (pressedInside) return;
    if (this.#isAllowedOutsideClick(e.target)) return;
    this.hideModal();
  }

  #isAllowedOutsideClick(target) {
    if (!this.allowedClickOutsideSelectorValue) return false;
    return target.closest(this.allowedClickOutsideSelectorValue) !== null;
  }

  #resetModalElement() {
    const historyWasAdvanced = this.#hasHistoryAdvanced();
    this.containerTarget.dataset.utmrHistoryAdvanced = String(historyWasAdvanced);
    this.containerTarget.dataset.utmrSkipHistoryBack = String(!!this._skipHistoryBack);
    this.#applyClosingState();
    this.#queueCloseCleanup(historyWasAdvanced);
  }

  #resumeClosing() {
    const historyWasAdvanced = this.containerTarget.dataset.utmrHistoryAdvanced == 'true';
    this._skipHistoryBack = this.containerTarget.dataset.utmrSkipHistoryBack == 'true';

    // Same-page morphs can reconnect the controller mid-close before the browser
    // has committed the leave transition. Re-arm the closing state on the
    // reconnected node so the drawer/modal still animates out smoothly.
    this.containerTarget.removeAttribute('data-closing');
    this.containerTarget.setAttribute('data-enter-ready', '');
    this.containerTarget.setAttribute('data-entered', '');
    this.#cancelResumeClosing();

    this.closeFrames = [];
    const outerFrame = requestAnimationFrame(() => {
      if (!this.containerTarget.isConnected) return;

      const innerFrame = requestAnimationFrame(() => {
        if (!this.containerTarget.isConnected) return;
        this.#applyClosingState();
        this.closeFrames = null;
        this.#queueCloseCleanup(historyWasAdvanced);
      });
      this.closeFrames?.push(innerFrame);
    });
    this.closeFrames.push(outerFrame);
  }

  #applyClosingState() {
    this.containerTarget.setAttribute('data-closing', '');
    this.containerTarget.setAttribute('data-enter-ready', '');
    this.containerTarget.removeAttribute('data-entered');
    this.#cancelEnter();
  }

  #queueCloseCleanup(historyWasAdvanced) {
    const dialog = this.containerTarget;
    const transitionTarget = this.#transitionTarget();
    const closeTimeoutMs = this.#isDrawer() ? 750 : 300;
    this.#cancelCloseCleanup();

    let cleaned = false;
    const cleanup = () => {
      if (cleaned) return;
      cleaned = true;
      this.#cancelCloseCleanup();
      window.removeEventListener('popstate', this.popstateHandler);
      const frame = this.turboFrame;
      try { dialog.close(); } catch (_) {}
      try { frame.removeAttribute("src"); } catch (_) {}
      try { dialog.remove(); } catch (_) {}
      delete dialog.dataset.utmrHistoryAdvanced;
      delete dialog.dataset.utmrSkipHistoryBack;
      this.#releaseScrollbarCompensation();
      this.#resetHistoryAdvanced();
      try { frame.dispatchEvent(new Event('modal:closed', { cancelable: false })); } catch (_) {}

      // Go back in history AFTER the dialog is removed and animation is done.
      // This triggers Turbo's popstate navigation to restore the previous page.
      if (historyWasAdvanced && !this._skipHistoryBack) history.back();
    };

    const onTransitionEnd = (e) => {
      if (e.target === transitionTarget) cleanup();
    };

    this.closeTransitionHandler = onTransitionEnd;
    dialog.addEventListener('transitionend', onTransitionEnd);
    // Fallback if no transition defined (custom flavor with empty classes)
    this.closeTimeout = setTimeout(cleanup, closeTimeoutMs);
  }

  // Quick cleanup without animation — used when the browser back button
  // is pressed and Turbo is already navigating to the previous page.
  #immediateCleanup() {
    this.#cancelEnter();
    this.#cancelResumeClosing();
    this.#cancelCloseCleanup();
    const dialog = this.containerTarget;
    const frame = this.turboFrame;
    try { dialog.close(); } catch (_) {}
    try { frame.removeAttribute("src"); } catch (_) {}
    try { dialog.remove(); } catch (_) {}
    this.#releaseScrollbarCompensation();
    try { frame.dispatchEvent(new Event('modal:closed', { cancelable: false })); } catch (_) {}
  }

  // Remove any stale dialogs of the same kind left over from a previous failed
  // close. Scoped to the current dialog's id so stacked dialogs don't tear
  // down their ancestor (e.g. a stacked modal opening inside a drawer).
  #cleanupStaleDialogs() {
    const selector = `dialog#${CSS.escape(this.containerTarget.id)}`;
    document.querySelectorAll(selector).forEach(d => {
      if (d !== this.containerTarget) {
        try { d.close(); } catch (_) {}
        d.remove();
      }
    });
  }

  #isDrawer() {
    return this.containerTarget.dataset.drawer !== undefined
  }

  #isStacked() {
    return this.containerTarget.id === 'modal-container-stacked';
  }

  // The element that runs the enter/leave CSS transition. The
  // `#queueCloseCleanup` listener waits for `transitionend` on this element to
  // know when the leave animation has completed.
  //
  // Note: the inner id (`modal-inner` / `modal-inner-stacked`) is shared by a
  // wrapping `<turbo-frame>` AND the `<div>` that actually carries the
  // transition classes. We need the DIV — `querySelector('#modal-inner')`
  // would return the frame instead.
  #transitionTarget() {
    if (this.#isDrawer()) return this.containerTarget.querySelector('#drawer-panel');
    const innerSelector = this.#isStacked() ? 'div#modal-inner-stacked' : 'div#modal-inner';
    return this.containerTarget.querySelector(innerSelector);
  }

  #queueEnter() {
    this.#cancelEnter();

    this.enterFrames = [];
    const outerFrame = requestAnimationFrame(() => {
      if (!this.containerTarget.isConnected || this.containerTarget.hasAttribute('data-closing')) return;
      this.containerTarget.setAttribute('data-enter-ready', '');

      const innerFrame = requestAnimationFrame(() => {
        if (!this.containerTarget.isConnected || this.containerTarget.hasAttribute('data-closing')) return;
        this.containerTarget.setAttribute('data-entered', '');
        this.enterFrames = null;
      });
      this.enterFrames?.push(innerFrame);
    });
    this.enterFrames.push(outerFrame);
  }

  #cancelEnter() {
    if (!this.enterFrames) return;
    this.enterFrames.forEach(id => cancelAnimationFrame(id));
    this.enterFrames = null;
  }

  #cancelResumeClosing() {
    if (!this.closeFrames) return;
    this.closeFrames.forEach(id => cancelAnimationFrame(id));
    this.closeFrames = null;
  }

  #cancelCloseCleanup() {
    clearTimeout(this.closeTimeout);
    this.closeTimeout = null;

    if (!this.closeTransitionHandler) return;
    this.containerTarget.removeEventListener('transitionend', this.closeTransitionHandler);
    this.closeTransitionHandler = null;
  }

  #applyScrollbarCompensation() {
    if (this._holdsScrollLock) return;
    if (scrollLockOwners.size === 0 && !scrollbarPaddingApplied) {
      const sbw = window.innerWidth - document.documentElement.clientWidth;
      if (sbw > 0) {
        savedPaddingRight = document.documentElement.style.paddingRight;
        document.documentElement.style.paddingRight = `${sbw}px`;

        compensatedFixedElements = [];
        document.querySelectorAll('*').forEach(el => {
          if (el.closest('dialog')) return;
          const cs = getComputedStyle(el);
          if (cs.position !== 'fixed') return;
          if (cs.right === 'auto') return;
          const currentRight = parseFloat(cs.right) || 0;
          compensatedFixedElements.push({ el, originalRight: el.style.right });
          el.style.right = `${currentRight + sbw}px`;
        });

        scrollbarPaddingApplied = true;
      }
    }
    scrollLockOwners.add(this);
    this._holdsScrollLock = true;
  }

  #releaseScrollbarCompensation() {
    if (!this._holdsScrollLock) return;
    scrollLockOwners.delete(this);
    this._holdsScrollLock = false;
    if (scrollLockOwners.size === 0 && scrollbarPaddingApplied) {
      document.documentElement.style.paddingRight = savedPaddingRight;
      savedPaddingRight = '';
      compensatedFixedElements.forEach(({ el, originalRight }) => {
        if (originalRight) el.style.right = originalRight;
        else el.style.removeProperty('right');
      });
      compensatedFixedElements = [];
      scrollbarPaddingApplied = false;
    }
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

  // Normalize a version string so Ruby gem format ("3.0.0.alpha.1") and
  // npm/semver format ("3.0.0-alpha.1") can be compared reliably.
  #normalizeVersion(v) {
    return v
      .replace(/\.([a-z]+)(?:\.(\d+))?$/, (_, tag, num) => `-${tag}.${num || '0'}`) // "3.0.0.alpha.1" → "3.0.0-alpha.1", "3.0.0.alpha" → "3.0.0-alpha.0"
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
