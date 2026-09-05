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
let closeTokenSequence = 0;

export default class extends Controller {
  // Resolvers for in-flight hideModalWithPromise() calls. A close can end
  // without the dialog ever closing -- a morph can supersede it, or the
  // controller can disconnect -- and those callers still have to be released.
  // They are settled directly rather than through modal:closed so that event
  // keeps meaning "this dialog is closed and gone".
  #closeWaiters = new Set()

  static targets = ["container", "content"]
  static values = {
    advanceUrl: String,
    allowedClickOutsideSelector: String,
    closeOnSubmit: { type: Boolean, default: true }
  }

  connect() {
    this.#checkVersions();
    this.#cleanupStaleDialogs();
    this.turboFrame = this.element.closest('turbo-frame');
    this.hidingModal = this.containerTarget.hasAttribute('data-closing');
    this.originalUrl = window.location.href;
    this.containerTarget.__ultimateTurboModalController = this;

    if (!dialogStack.includes(this)) dialogStack.push(this);
    if (!this.hidingModal) delete this.turboFrame?.dataset.utmrCloseToken;

    // Same-page morphs can briefly disconnect/reconnect the controller while the
    // dialog is already open. Replaying showModal() there re-triggers the enter
    // animation and causes a visible reopen during close.
    if (this.hidingModal) {
      this.#adoptScrollLock();
      this.#resumeClosing();
    } else if (!this.containerTarget.open) {
      this.showModal();
    } else {
      this.#adoptScrollLock();
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

    // Handle Escape before the browser's native dialog cancel/close behavior.
    // The native `cancel` event remains as a fallback, but routing the key
    // through the topmost UTMR controller avoids abrupt native closes after a
    // stacked modal has just been removed from above a drawer.
    this.keydownHandler = (event) => {
      if (event.key !== 'Escape') return;
      if (event.defaultPrevented) return;
      if (dialogStack[dialogStack.length - 1] !== this) return;

      event.preventDefault();
      this.hideModal();
    };
    document.addEventListener('keydown', this.keydownHandler);

    window.modal = dialogStack[dialogStack.length - 1];
  }

  disconnect() {
    this.#cancelEnter();
    this.#cancelResumeClosing();
    this.#cancelCloseCleanup();
    window.removeEventListener('popstate', this.popstateHandler);
    document.removeEventListener('turbo:before-cache', this.beforeCacheHandler);
    document.removeEventListener('keydown', this.keydownHandler);
    this.#releaseScrollLockSlot();
    this.#settleCloseWaiters();

    if (this.containerTarget.__ultimateTurboModalController === this) {
      delete this.containerTarget.__ultimateTurboModalController;
    }

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
      let timeout = null;
      let settled = false;
      const settle = () => {
        if (settled) return;
        settled = true;
        frame?.removeEventListener('modal:closed', settle);
        this.#closeWaiters.delete(settle);
        clearTimeout(timeout);
        resolve();
      };
      this.#closeWaiters.add(settle);
      frame?.addEventListener('modal:closed', settle);
      // Last resort. Every path that ends a close settles its waiters, but a
      // caller awaiting this promise must never hang on a missed one.
      timeout = setTimeout(settle, this.#closeTimeoutMs() + 100);
      if (this.hideModal(options) === false) settle();
    });
  }

  #settleCloseWaiters() {
    const waiters = Array.from(this.#closeWaiters);
    this.#closeWaiters.clear();
    waiters.forEach(settle => settle());
  }

  hide() {
    this.hideModal();
  }

  close() {
    this.hideModal();
  }

  reviveAfterFrameMorph() {
    this.#cancelResumeClosing();
    this.#cancelCloseCleanup();
    if (this.#frameOwnsCloseToken(this.turboFrame, this._closeToken)) {
      delete this.turboFrame.dataset.utmrCloseToken;
    }
    this._closeToken = null;
    this.hidingModal = false;
    this._skipHistoryBack = false;
    this.containerTarget.removeAttribute('data-closing');
    delete this.containerTarget.dataset.utmrCloseToken;
    delete this.containerTarget.dataset.utmrHistoryAdvanced;
    delete this.containerTarget.dataset.utmrSkipHistoryBack;

    if (!this.containerTarget.open) {
      this.showModal();
    } else {
      this.#adoptScrollLock();
      this.containerTarget.setAttribute('data-enter-ready', '');
      this.containerTarget.setAttribute('data-entered', '');
    }

    // The close is over, but it was cancelled rather than completed: this
    // dialog is on screen with newer content. Release anyone awaiting it
    // without claiming it closed.
    this.#settleCloseWaiters();
  }

  refreshPage() {
    window.Turbo.visit(window.location.href, { action: "replace" });
  }

  // hide modal on successful form submission
  // action: "turbo:submit-end->modal#submitEnd"
  submitEnd(e) {
    if (!e.detail.success) return;

    const response = e.detail.fetchResponse?.response;
    if (response?.redirected) {
      // Record the redirect even when close-on-submit is off. The response
      // navigates away from this page, so the dialog can't stay open either
      // way, and turbo:frame-missing needs the final URL to visit.
      this._pendingRedirectUrl = response.url;
      return;
    }

    if (!this.#closesOnSubmit(e.target)) return;
    this.hideModal();
  }

  // `data-modal-close-on-submit` on the submitted form -- or on any element
  // between it and this dialog -- overrides the dialog-wide `close_on_submit`
  // setting. Lets one modal mix forms that dismiss it with forms that don't.
  #closesOnSubmit(target) {
    const override = target?.closest?.('[data-modal-close-on-submit]');
    if (override && this.element.contains(override)) {
      return override.dataset.modalCloseOnSubmit !== 'false';
    }
    return this.closeOnSubmitValue;
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
    this.#stampCloseToken();
    this.#applyClosingState();
    this.#queueCloseCleanup(historyWasAdvanced);
  }

  #resumeClosing() {
    const historyWasAdvanced = this.containerTarget.dataset.utmrHistoryAdvanced == 'true';
    this._skipHistoryBack = this.containerTarget.dataset.utmrSkipHistoryBack == 'true';
    // Reconnecting cannot reclaim a frame that a newer request already owns.
    this._closeToken = this.containerTarget.dataset.utmrCloseToken;

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

  #stampCloseToken() {
    const closeToken = String(++closeTokenSequence);
    this._closeToken = closeToken;
    this.containerTarget.dataset.utmrCloseToken = closeToken;
    if (this.turboFrame) this.turboFrame.dataset.utmrCloseToken = closeToken;
    return closeToken;
  }

  #frameOwnsCloseToken(frame, closeToken) {
    return !!closeToken && frame?.dataset.utmrCloseToken === closeToken;
  }

  // Neither the dialog node nor the frame is unconditionally ours by the time
  // cleanup runs, so both cleanup paths ask these two questions.
  //
  // handleTurboBeforeFrameRender morphs in-frame updates onto the existing
  // dialog, so a newer modal can be living in the very node this close was
  // started on. data-closing is the tell: #applyClosingState sets it when the
  // close begins and the server never renders it, so a morph removes it.
  // Outside a close nothing has superseded us, so the node is ours.
  #stillOwnsDialog() {
    if (!this.hidingModal) return true;
    // #resumeClosing clears data-closing for two frames while it re-arms the
    // leave animation on a reconnected node. The dialog is still ours there.
    if (this.closeFrames) return true;
    return this.containerTarget.hasAttribute('data-closing');
  }

  // Mid-close a newer request or a newer modal may already own the frame, and
  // the close token is the only reliable tell -- a src comparison reads equal
  // for stream-delivered modals and for reopening the same URL. Outside a close
  // nothing else has stamped the frame, so containment is enough.
  #stillOwnsFrame() {
    const frame = this.turboFrame;
    if (!frame) return false;
    return this.hidingModal
      ? this.#frameOwnsCloseToken(frame, this._closeToken)
      : this.containerTarget.closest('turbo-frame') === frame;
  }

  #queueCloseCleanup(historyWasAdvanced) {
    const dialog = this.containerTarget;
    const transitionTarget = this.#transitionTarget();
    const closeTimeoutMs = this.#closeTimeoutMs();
    this.#cancelCloseCleanup();

    let cleaned = false;
    const cleanup = () => {
      if (cleaned) return;
      cleaned = true;
      this.#cancelCloseCleanup();
      const frame = this.turboFrame;
      const frameStillOurs = this.#stillOwnsFrame();
      const dialogStillOurs = this.#stillOwnsDialog();

      if (dialogStillOurs) {
        window.removeEventListener('popstate', this.popstateHandler);
        try { dialog.close(); } catch (_) {}
        try { dialog.remove(); } catch (_) {}
        delete dialog.dataset.utmrCloseToken;
        delete dialog.dataset.utmrHistoryAdvanced;
        delete dialog.dataset.utmrSkipHistoryBack;
        this.#releaseScrollbarCompensation();
      }

      if (frameStillOurs) {
        try { frame.removeAttribute("src"); } catch (_) {}
        delete frame.dataset.utmrCloseToken;
      }

      // Only consume the history entry when the replacement modal will not
      // inherit it. When the frame has moved on, leaving the body flag set
      // stops that modal pushing a second entry, and its own close spends this
      // one -- and history.back() here would kick off a restoration visit that
      // races the incoming frame render.
      if (dialogStillOurs && frameStillOurs) {
        this.#resetHistoryAdvanced();
      }

      if (dialogStillOurs) {
        try { frame?.dispatchEvent(new Event('modal:closed', { cancelable: false })); } catch (_) {}
      }
      this.#settleCloseWaiters();

      // Go back in history AFTER the dialog is removed and animation is done.
      // This triggers Turbo's popstate navigation to restore the previous page.
      if (dialogStillOurs && frameStillOurs && historyWasAdvanced && !this._skipHistoryBack) history.back();
    };

    const onTransitionEnd = (e) => {
      if (e.target === transitionTarget) cleanup();
    };

    this.closeTransitionHandler = onTransitionEnd;
    dialog.addEventListener('transitionend', onTransitionEnd);
    // Fallback if no transition defined (custom flavor with empty classes)
    this.closeTimeout = setTimeout(cleanup, closeTimeoutMs);
  }

  #closeTimeoutMs() {
    return this.#isDrawer() ? 750 : 300;
  }

  // Quick cleanup without animation — used when the browser back button
  // is pressed and Turbo is already navigating to the previous page.
  #immediateCleanup() {
    // Read ownership before cancelling, since #cancelResumeClosing closes the
    // window #stillOwnsDialog uses to recognise a reconnecting close.
    const dialogStillOurs = this.#stillOwnsDialog();
    const frameStillOurs = this.#stillOwnsFrame();
    this.#cancelEnter();
    this.#cancelResumeClosing();
    this.#cancelCloseCleanup();
    const dialog = this.containerTarget;
    const frame = this.turboFrame;

    if (dialogStillOurs) {
      try { dialog.close(); } catch (_) {}
      try { dialog.remove(); } catch (_) {}
      delete dialog.dataset.utmrCloseToken;
      delete dialog.dataset.utmrHistoryAdvanced;
      delete dialog.dataset.utmrSkipHistoryBack;
      this.#releaseScrollbarCompensation();
    }

    if (frameStillOurs) {
      try { frame.removeAttribute("src"); } catch (_) {}
      delete frame.dataset.utmrCloseToken;
    }

    if (dialogStillOurs) {
      try { frame?.dispatchEvent(new Event('modal:closed', { cancelable: false })); } catch (_) {}
    }
    this.#settleCloseWaiters();
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
      this.#restoreScrollbarCompensation();
    }
  }

  // Take ownership of an existing scroll lock when reconnecting to a dialog
  // that's already open (e.g. same-page morph). The actual padding/offset
  // compensation is already applied by the previous controller instance — we
  // just need to register so the eventual close releases it.
  #adoptScrollLock() {
    if (this._holdsScrollLock) return;
    if (!scrollbarPaddingApplied) return;
    scrollLockOwners.add(this);
    this._holdsScrollLock = true;
  }

  // Release this controller's slot in the scroll-lock set during disconnect.
  // Compensation restoration is deferred so an immediate Stimulus reconnect
  // (same-page morph) can adopt the lock before everything is torn down.
  #releaseScrollLockSlot() {
    if (!this._holdsScrollLock) return;
    scrollLockOwners.delete(this);
    this._holdsScrollLock = false;
    queueMicrotask(() => {
      if (scrollLockOwners.size === 0 && scrollbarPaddingApplied) {
        this.#restoreScrollbarCompensation();
      }
    });
  }

  #restoreScrollbarCompensation() {
    document.documentElement.style.paddingRight = savedPaddingRight;
    savedPaddingRight = '';
    compensatedFixedElements.forEach(({ el, originalRight }) => {
      if (originalRight) el.style.right = originalRight;
      else el.style.removeProperty('right');
    });
    compensatedFixedElements = [];
    scrollbarPaddingApplied = false;
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
