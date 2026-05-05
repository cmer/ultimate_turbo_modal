import UltimateTurboModalController from './modal_controller.js';
import { Idiomorph } from 'idiomorph';
import './styles/vanilla.css';

Turbo.StreamActions.modal = function () {
  const message = this.getAttribute("message");
  if (message == "hide" || message == "close") window.modal?.hide();
};

// Frame ids managed by UTMR — primary modal/drawer + stacked-modal frames.
const MODAL_FRAME_IDS = new Set([
  'modal',
  'modal-inner',
  'drawer-modal',
  'modal-inner-stacked'
]);

// Check if the event target is one of our modal Turbo Frames
const isModalFrameTarget = (event) => {
  const target = event?.target;
  return (
    target instanceof Element &&
    target.tagName.toLowerCase() === 'turbo-frame' &&
    MODAL_FRAME_IDS.has(target.id)
  );
};

const isSamePageUrl = (url1, url2) => {
  try {
    const a = new URL(url1, window.location.origin);
    const b = new URL(url2, window.location.origin);
    return a.pathname === b.pathname;
  } catch { return false; }
};

const morphPageBehindModal = (html) => {
  const doc = new DOMParser().parseFromString(html, 'text/html');
  Idiomorph.morph(document.body, doc.body, {
    morphStyle: 'innerHTML',
    ignoreActiveValue: true,
    callbacks: {
      beforeNodeMorphed: (oldNode) => {
        if (oldNode.id === 'modal-container' || oldNode.id === 'modal-container-stacked') return false;
        if (oldNode.tagName?.toLowerCase() === 'turbo-frame' && MODAL_FRAME_IDS.has(oldNode.id)) return false;
        return true;
      }
    }
  });
};

// Count of UTMR dialogs currently in the DOM and open
const openDialogCount = () =>
  document.querySelectorAll('dialog.utmr[open]').length;

// Close every open UTMR dialog from top to bottom, awaiting each animation.
// window.modal points to the topmost dialog and auto-rotates as each one
// disconnects.
//
// Subtlety: hideModalWithPromise resolves on `modal:closed`, but window.modal
// is only rotated inside Stimulus's disconnect (fired by MutationObserver
// after the dialog is removed from the DOM). We yield once after each close
// so disconnect has a chance to run before the next iteration reads
// window.modal — otherwise we'd loop on the same already-hiding controller
// and burn through the safety counter. We also bail out when window.modal
// hasn't rotated, which catches `modal:closing` vetoes (preventDefault).
const closeAllDialogs = async () => {
  let safety = 5;
  while (window.modal && safety-- > 0) {
    const ctrl = window.modal;
    await ctrl.hideModalWithPromise({ skipHistoryBack: true });
    await new Promise(r => setTimeout(r, 0));
    if (window.modal === ctrl) break;
  }
};

// Perform a smooth redirect: morph same-page content or close-then-navigate
const performSmoothRedirect = async (modal, redirectUrl) => {
  const originalUrl = modal.originalUrl;
  // True when this modal is stacked over another open dialog (e.g., a drawer).
  // In that case we must NOT morph the body — the morph would clobber the
  // sibling dialog's DOM. Just close this modal and update the URL.
  const hasSibling = openDialogCount() > 1;

  if (isSamePageUrl(originalUrl, redirectUrl)) {
    if (hasSibling) {
      if (redirectUrl !== window.location.href) {
        history.replaceState({}, '', redirectUrl);
      }
      await modal.hideModalWithPromise({ skipHistoryBack: true });
      return;
    }

    // Same-page: fetch fresh HTML, morph body behind modal, then close
    try {
      const freshResponse = await fetch(redirectUrl, {
        headers: { 'Accept': 'text/html' }
      });
      const html = await freshResponse.text();
      morphPageBehindModal(html);
    } catch (_) {
      // If morph fails, fall back to close + navigate
      await modal.hideModalWithPromise({ skipHistoryBack: true });
      window.Turbo.visit(redirectUrl);
      return;
    }
    if (redirectUrl !== window.location.href) {
      history.replaceState({}, '', redirectUrl);
    }
    await modal.hideModalWithPromise({ skipHistoryBack: true });
  } else {
    // Different page: close every open dialog first (so a sibling drawer
    // doesn't get stranded on the new page), then navigate.
    if (hasSibling) {
      await closeAllDialogs();
    } else {
      await modal.hideModalWithPromise({ skipHistoryBack: true });
    }
    window.Turbo.visit(redirectUrl);
  }
};

// Escape modal when the target frame is missing from the response.
// This handles redirects to pages that don't contain the modal frame,
// and regular links (e.g., <a href="/">) clicked inside the modal/drawer.
const handleTurboFrameMissing = (event) => {
  if (!isModalFrameTarget(event)) return;
  event.preventDefault();

  const modal = window.modal;
  if (!modal) {
    event.detail.visit(event.detail.response);
    return;
  }

  // Check if submitEnd stored a redirect URL
  const redirectUrl = modal._pendingRedirectUrl || event.detail.response.url;
  modal._pendingRedirectUrl = null;

  performSmoothRedirect(modal, redirectUrl);
};

// Intercept frame renders for modal frames to use Idiomorph for flicker-free updates.
// When turbo:before-frame-render fires, the response *contains* the modal frame,
// so it's valid modal content (e.g., a wizard step or in-modal navigation).
// Redirect responses that *don't* contain the frame are handled by turbo:frame-missing.
const handleTurboBeforeFrameRender = (event) => {
  if (!isModalFrameTarget(event)) return;

  // If submitEnd flagged a redirect but the response contains the modal frame,
  // it's a redirect to another modal action (e.g., multi-step wizard). Clear the
  // flag and let the frame render normally so the next step appears in the modal.
  const modal = window.modal;
  if (modal?._pendingRedirectUrl) {
    modal._pendingRedirectUrl = null;
  }

  // Empty modal frames are initial loads. Let Turbo do its normal child
  // replacement so Stimulus sees a plain insertion and owns dialog opening.
  if (event.target.children.length === 0) return;

  // Morph subsequent in-frame updates to prevent flicker and avoid re-running
  // enter transitions on an already-open dialog.
  event.detail.render = (currentElement, newElement) => {
    Idiomorph.morph(currentElement, Array.from(newElement.childNodes), {
      morphStyle: 'innerHTML'
    });
  };
};

// Auto-route modal-bound clicks/submissions to the drawer's stacked-modal
// frame when they originate from inside an open drawer. Lets a partial use
// `data-turbo-frame="modal"` everywhere — outside a drawer it opens a regular
// modal, inside a drawer it opens stacked. No `data-turbo-frame` still means
// "navigate inside the drawer".
//
// Basic strategy: once drawer content is in the DOM, normalize its
// modal-targeted links/forms/buttons to target the drawer's local stacked frame.
// Turbo then handles normal clicks and submissions itself, including sending
// `Turbo-Frame: drawer-modal`.

const ORIGINAL_TURBO_FRAME_ATTR = 'data-utmr-original-turbo-frame';
const DRAWER_TARGET_OBSERVER_KEY = '__utmrDrawerTargetObserver';

const drawerDialogsFor = (root = document) => {
  const dialogs = new Set();

  if (root instanceof Element) {
    const owningDrawer = root.closest('dialog.utmr[data-drawer]');
    if (owningDrawer) dialogs.add(owningDrawer);
    if (root.matches('dialog.utmr[data-drawer]')) dialogs.add(root);
    root.querySelectorAll('dialog.utmr[data-drawer]').forEach((dialog) => dialogs.add(dialog));
  } else {
    document.querySelectorAll('dialog.utmr[data-drawer]').forEach((dialog) => dialogs.add(dialog));
  }

  return dialogs;
};

const routeDrawerModalTargets = (root = document) => {
  drawerDialogsFor(root).forEach((dialog) => {
    if (!dialog.querySelector('turbo-frame#drawer-modal')) return;

    dialog.querySelectorAll('[data-turbo-frame="modal"]').forEach((target) => {
      // Do not retarget controls inside a stacked modal rendered within the drawer.
      if (target.closest('dialog.utmr') !== dialog) return;

      if (!target.hasAttribute(ORIGINAL_TURBO_FRAME_ATTR)) {
        target.setAttribute(ORIGINAL_TURBO_FRAME_ATTR, 'modal');
      }
      target.setAttribute('data-turbo-frame', 'drawer-modal');
    });
  });
};

const handleTurboFrameRender = (event) => {
  if (!isModalFrameTarget(event)) return;
  routeDrawerModalTargets(event.target);
};

window[DRAWER_TARGET_OBSERVER_KEY]?.disconnect?.();
window[DRAWER_TARGET_OBSERVER_KEY] = new MutationObserver((mutations) => {
  mutations.forEach((mutation) => {
    if (mutation.type === 'attributes') {
      routeDrawerModalTargets(mutation.target);
      return;
    }

    mutation.addedNodes.forEach((node) => {
      if (node instanceof Element) routeDrawerModalTargets(node);
    });
  });
});

routeDrawerModalTargets();
window[DRAWER_TARGET_OBSERVER_KEY].observe(document.documentElement, {
  childList: true,
  subtree: true,
  attributes: true,
  attributeFilter: ['data-turbo-frame']
});

document.removeEventListener("turbo:frame-missing", handleTurboFrameMissing);
document.addEventListener("turbo:frame-missing", handleTurboFrameMissing);

document.removeEventListener("turbo:before-frame-render", handleTurboBeforeFrameRender);
document.addEventListener("turbo:before-frame-render", handleTurboBeforeFrameRender);

document.removeEventListener("turbo:frame-render", handleTurboFrameRender);
document.addEventListener("turbo:frame-render", handleTurboFrameRender);

// Clean up any modal dialogs before Turbo caches the page.
// The Stimulus controller has its own turbo:before-cache handler, but if the
// controller has already disconnected or cleanup failed, the dialog can survive
// into the cache and leave the page in a broken state on restore.
const handleTurboBeforeCache = () => {
  document.querySelectorAll('dialog.utmr').forEach(d => {
    try { d.close(); } catch (_) {}
    d.remove();
  });
  document.body.removeAttribute('data-turbo-modal-history-advanced');
};

document.removeEventListener("turbo:before-cache", handleTurboBeforeCache);
document.addEventListener("turbo:before-cache", handleTurboBeforeCache);

export { UltimateTurboModalController };
