import { Controller } from '@hotwired/stimulus';
import { enter, leave } from 'el-transition';
import { Idiomorph } from 'idiomorph';

// This placeholder will be replaced by rollup

const PACKAGE_VERSION = '__PACKAGE_VERSION__';

const SELECTORS = {
  TURBO_FRAME: 'turbo-frame',
  MODAL_CONTAINER: '#modal-container',
  MODAL_FRAME: 'turbo-frame[id="modal"]'
};

const TIMING = {
  MODAL_CLOSE_DELAY: 150 // Delay to ensure modal close animation completes
};

const EVENTS = {
  POPSTATE: 'popstate',
  TURBO_BEFORE_VISIT: 'turbo:before-visit',
  TURBO_FRAME_MISSING: 'turbo:frame-missing',
  TURBO_SUBMIT_END: 'turbo:submit-end',
  MODAL_CLOSING: 'modal:closing',
  MODAL_CLOSED: 'modal:closed',
  KEYUP: 'keyup',
  CLICK: 'click'
};

const DATA_ATTRS = {
  HISTORY_ADVANCED: 'data-turbo-modal-history-advanced',
  VERSION: 'utmrVersion'
};

const REDIRECT_BEHAVIORS = {
  SMOOTH: 'smooth',
  IMMEDIATE: 'immediate'
};

/**
 * Modal controller for Ultimate Turbo Modal
 * Manages modal display, interactions, and smooth redirect behavior
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["container", "content"]
  static values = {
    advanceUrl: String,
    allowedClickOutsideSelector: String,
    redirectBehavior: { type: String, default: REDIRECT_BEHAVIORS.SMOOTH }
  }

  /**
   * Initialize modal when controller connects
   */
  connect() {
    this.#initialize();
    this.#setupEventListeners();
    this.#checkVersions();
    this.showModal();
    
    // Make modal accessible globally for debugging
    window.modal = this;
  }

  /**
   * Clean up when controller disconnects
   */
  disconnect() {
    this.#removeEventListeners();
    window.modal = undefined;
  }

  /**
   * Show the modal with animation
   */
  showModal() {
    enter(this.containerTarget);
    
    if (this.advanceUrlValue && !this.#hasHistoryAdvanced()) {
      this.#advanceHistory();
    }
  }

  /**
   * Hide the modal with proper cleanup
   * Handles history navigation if URL was advanced
   */
  hideModal() {
    // Prevent multiple simultaneous calls
    if (this.hidingModal) return;
    this.hidingModal = true;

    // Dispatch closing event (cancelable)
    if (!this.#dispatchModalEvent(EVENTS.MODAL_CLOSING, true)) {
      this.hidingModal = false;
      return;
    }

    this.#resetModalElement();
    
    // Dispatch closed event (not cancelable)
    this.#dispatchModalEvent(EVENTS.MODAL_CLOSED, false);

    // Navigate back if history was advanced
    if (this.#hasHistoryAdvanced()) {
      history.back();
    }
  }

  /**
   * Alias for hideModal for backwards compatibility
   */
  hide() {
    this.hideModal();
  }

  /**
   * Refresh the current page using Turbo
   */
  refreshPage() {
    window.Turbo.visit(window.location.href, { action: "replace" });
  }

  /**
   * Handle form submission end
   * @param {Event} e - Turbo submit end event
   */
  submitEnd(e) {
    if (!e.detail.success) return;
    
    // Only close immediately if not using smooth redirect behavior
    if (this.redirectBehaviorValue !== REDIRECT_BEHAVIORS.SMOOTH) {
      this.hideModal();
    }
  }

  /**
   * Close modal on ESC key press
   * @param {KeyboardEvent} e - Keyboard event
   */
  closeWithKeyboard(e) {
    if (e.code === "Escape") {
      this.hideModal();
    }
  }

  /**
   * Handle clicks outside the modal
   * @param {MouseEvent} e - Click event
   */
  outsideModalClicked(e) {
    if (this.#isClickOutsideModal(e) && !this.#isClickOnAllowedElement(e)) {
      this.hideModal();
    }
  }

  // Private methods

  /**
   * Initialize controller properties
   * @private
   */
  #initialize() {
    this.turboFrame = this.element.closest(SELECTORS.TURBO_FRAME);
    this.hidingModal = false;
    this.pendingNavigationUrl = null;
    // Store original URL before any modal history advancement
    this.originalUrl = window.location.href;
  }

  /**
   * Set up event listeners based on configuration
   * @private
   */
  #setupEventListeners() {
    // History navigation listener
    this.popstateHandler = () => {
      if (this.#hasHistoryAdvanced()) {
        this.#resetModalElement();
      }
    };
    window.addEventListener(EVENTS.POPSTATE, this.popstateHandler);

    // Smooth redirect behavior listeners
    if (this.redirectBehaviorValue === REDIRECT_BEHAVIORS.SMOOTH) {
      this.visitHandler = this.#interceptFrameBreakingVisit.bind(this);
      this.frameMissingHandler = this.#handleFrameMissing.bind(this);
      
      document.addEventListener(EVENTS.TURBO_BEFORE_VISIT, this.visitHandler);
      this.turboFrame.addEventListener(EVENTS.TURBO_FRAME_MISSING, this.frameMissingHandler);
    }
  }

  /**
   * Remove event listeners
   * @private
   */
  #removeEventListeners() {
    window.removeEventListener(EVENTS.POPSTATE, this.popstateHandler);
    
    if (this.visitHandler) {
      document.removeEventListener(EVENTS.TURBO_BEFORE_VISIT, this.visitHandler);
    }
    if (this.frameMissingHandler) {
      this.turboFrame.removeEventListener(EVENTS.TURBO_FRAME_MISSING, this.frameMissingHandler);
    }
  }

  /**
   * Check for version mismatches between gem and JavaScript
   * @private
   */
  #checkVersions() {
    const gemVersion = this.element.dataset[DATA_ATTRS.VERSION];
    
    if (!gemVersion) return; // Skip check if attribute not set
    
    if (gemVersion !== PACKAGE_VERSION) {
      console.warn(
        `[UltimateTurboModal] Version Mismatch!\n\n` +
        `Gem Version: ${gemVersion}\n` +
        `JS Version:  ${PACKAGE_VERSION}\n\n` +
        `Please ensure both the 'ultimate_turbo_modal' gem and the ` +
        `'ultimate-turbo-modal' npm package are updated to the same version.\n` +
        `Element:`, this.element
      );
    }
  }

  /**
   * Dispatch modal-specific events
   * @private
   * @param {string} eventName - Name of the event
   * @param {boolean} cancelable - Whether the event can be canceled
   * @returns {boolean} True if event was not prevented
   */
  #dispatchModalEvent(eventName, cancelable) {
    const event = new Event(eventName, { cancelable });
    this.turboFrame.dispatchEvent(event);
    return !event.defaultPrevented;
  }

  /**
   * Check if click was outside the modal content
   * @private
   * @param {MouseEvent} e - Click event
   * @returns {boolean}
   */
  #isClickOutsideModal(e) {
    return document.contains(e.target) && 
           !this.contentTarget.contains(e.target) && 
           this.contentTarget !== e.target;
  }

  /**
   * Check if click was on an allowed element
   * @private
   * @param {MouseEvent} e - Click event
   * @returns {boolean}
   */
  #isClickOnAllowedElement(e) {
    return this.allowedClickOutsideSelectorValue && 
           this.allowedClickOutsideSelectorValue !== '' && 
           e.target.closest(this.allowedClickOutsideSelectorValue) != null;
  }

  /**
   * Reset modal element with animation
   * @private
   */
  #resetModalElement() {
    leave(this.containerTarget).then(() => {
      this.turboFrame.removeAttribute("src");
      this.containerTarget.remove();
      this.#resetHistoryAdvanced();
    });
  }

  /**
   * History management methods
   * @private
   */
  #hasHistoryAdvanced() {
    return document.body.getAttribute(DATA_ATTRS.HISTORY_ADVANCED) === "true";
  }

  #advanceHistory() {
    this.#setHistoryAdvanced();
    history.pushState({}, "", this.advanceUrlValue);
  }

  #setHistoryAdvanced() {
    document.body.setAttribute(DATA_ATTRS.HISTORY_ADVANCED, "true");
  }

  #resetHistoryAdvanced() {
    document.body.removeAttribute(DATA_ATTRS.HISTORY_ADVANCED);
  }

  /**
   * Intercept frame-breaking navigation attempts
   * @private
   * @param {Event} event - Turbo before-visit event
   */
  #interceptFrameBreakingVisit(event) {
    const frameTarget = event.detail.frameElement?.id || '_top';
    const isBreakingFrame = frameTarget !== 'modal' && frameTarget !== this.turboFrame.id;
    const isFromModal = event.detail.element && this.element.contains(event.detail.element);
    
    if (isBreakingFrame && isFromModal) {
      event.preventDefault();
      this.#handleRedirect(event.detail.url);
    }
  }

  /**
   * Handle frame missing responses (typically redirects)
   * @private
   * @param {Event} event - Turbo frame-missing event
   */
  #handleFrameMissing(event) {
    event.preventDefault();
    this.#handleRedirect(event.detail.response.url, event.detail.response);
  }

  /**
   * Determine redirect type and handle accordingly
   * @private
   * @param {string} url - Target URL
   * @param {Response} response - Optional response object to avoid re-fetching
   */
  #handleRedirect(url, response = null) {
    // Compare redirect URL against original page URL, not current modal URL
    const originalPath = new URL(this.originalUrl).pathname;
    const newPath = new URL(url).pathname;
    
    if (originalPath === newPath) {
      this.#handleSamePageRedirect(url, response);
    } else {
      this.#handleDifferentPageRedirect(url);
    }
  }

  /**
   * Handle same-page redirects by morphing content
   * @private
   * @param {string} url - Target URL
   * @param {Response} response - Optional response object to avoid re-fetching
   */
  async #handleSamePageRedirect(url, response = null) {
    try {
      // Use existing response or fetch new page content
      if (!response) {
        response = await fetch(url, {
          headers: { 'Accept': 'text/html' }
        });
      }
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const html = await response.text();
      const newDocument = new DOMParser().parseFromString(html, 'text/html');
      
      // Morph page content excluding modal
      Idiomorph.morph(document.body, newDocument.body, {
        morphStyle: 'innerHTML',
        ignoreActiveValue: true,
        head: { style: 'merge' },
        callbacks: {
          beforeNodeMorphed: (oldNode, newNode) => {
            // Skip morphing modal elements
            if (oldNode.matches && (oldNode.matches(SELECTORS.MODAL_CONTAINER) || oldNode.matches(SELECTORS.MODAL_FRAME))) {
              return false;
            }
            return true;
          }
        }
      });
      
      // Update browser URL
      window.history.replaceState({}, '', url);
      
      // Close modal immediately while morphing happens
      this.hideModal();
      
    } catch (error) {
      console.error('[UltimateTurboModal] Failed to morph page:', error);
      // Fallback to regular navigation
      Turbo.visit(url);
    }
  }

  /**
   * Handle different-page redirects with smooth transition
   * @private
   * @param {string} url - Target URL
   */
  async #handleDifferentPageRedirect(url) {
    this.pendingNavigationUrl = url;
    this.hideModal();
    
    // Navigate after modal closes
    setTimeout(() => {
      if (this.pendingNavigationUrl) {
        Turbo.visit(this.pendingNavigationUrl, { action: 'advance' });
        this.pendingNavigationUrl = null;
      }
    }, TIMING.MODAL_CLOSE_DELAY);
  }
}