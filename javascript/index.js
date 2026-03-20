import UltimateTurboModalController from './modal_controller.js';
import { Idiomorph } from 'idiomorph';
import './styles/vanilla.css';

Turbo.StreamActions.modal = function () {
  const message = this.getAttribute("message");
  if (message == "hide" || message == "close") window.modal?.hide();
};

// Check if the event target is one of our modal Turbo Frames
const isModalFrameTarget = (event) => {
  const target = event?.target;
  return (
    target instanceof Element &&
    target.tagName.toLowerCase() === 'turbo-frame' &&
    (target.id === 'modal' || target.id === 'modal-inner')
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
        if (oldNode.id === 'modal-container') return false;
        if (oldNode.tagName?.toLowerCase() === 'turbo-frame' &&
            (oldNode.id === 'modal' || oldNode.id === 'modal-inner')) return false;
        return true;
      }
    }
  });
};

// Perform a smooth redirect: morph same-page content or close-then-navigate
const performSmoothRedirect = async (modal, redirectUrl) => {
  const originalUrl = modal.originalUrl;

  if (isSamePageUrl(originalUrl, redirectUrl)) {
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
    // Different page: close modal first, then navigate
    await modal.hideModalWithPromise({ skipHistoryBack: true });
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

  // Morph innerHTML to prevent flicker and avoid re-triggering enter transitions
  event.detail.render = (currentElement, newElement) => {
    Idiomorph.morph(currentElement, newElement, {
      morphstyle: 'innerHTML'
    })
  }
};

document.removeEventListener("turbo:frame-missing", handleTurboFrameMissing);
document.addEventListener("turbo:frame-missing", handleTurboFrameMissing);

document.removeEventListener("turbo:before-frame-render", handleTurboBeforeFrameRender);
document.addEventListener("turbo:before-frame-render", handleTurboBeforeFrameRender);

// Clean up any modal dialogs before Turbo caches the page.
// The Stimulus controller has its own turbo:before-cache handler, but if the
// controller has already disconnected or cleanup failed, the dialog can survive
// into the cache and leave the page in a broken state on restore.
const handleTurboBeforeCache = () => {
  document.querySelectorAll('dialog#modal-container, dialog.drawer-container').forEach(d => {
    try { d.close(); } catch (_) {}
    d.remove();
  });
  document.body.removeAttribute('data-turbo-modal-history-advanced');
};

document.removeEventListener("turbo:before-cache", handleTurboBeforeCache);
document.addEventListener("turbo:before-cache", handleTurboBeforeCache);

export { UltimateTurboModalController };
