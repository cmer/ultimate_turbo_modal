// Turbo Confirm support.
//
// The handler is installed when this package is imported, but it does nothing
// until the page carries the confirm <template>. Rendering
// `<%= modal_confirm_template %>` in the layout is what turns the feature on;
// without it every `data-turbo-confirm` falls through to `window.confirm`
// exactly as before. That keeps the whole switch on the Ruby side.
//
// The dialog is cloned from that server-rendered <template>, so it carries the
// app's flavor classes, and it is driven by the same `modal` Stimulus
// controller as every other UTMR dialog -- same enter/leave animation, scroll
// lock, Escape handling and stacking.

const TEMPLATE_ID = 'utmr-confirm-template';
const OPTION_KEYS = ['title', 'body', 'accept', 'cancel', 'variant', 'native'];

let installed = false;
let previousConfirm = null;

// The submitter is the more specific statement, so it is read first.
//
// A link is not in this list on purpose. Turbo rewrites a link carrying
// `data-turbo-method` into a hidden form and copies only a fixed set of
// attributes across, so sibling `data-turbo-confirm-*` attributes on a link are
// gone before Turbo calls us. The `modal_confirm` helper is the answer there:
// its JSON payload rides inside `data-turbo-confirm` itself and cannot be lost.
const optionSources = (formElement, submitter) => [submitter, formElement].filter(Boolean);

const readOptions = (message, sources) => {
  const options = {};

  // The `data-turbo-confirm` value is either a plain message or a JSON payload
  // (what the `modal_confirm` Ruby helper emits, since JSON survives Turbo's
  // link-to-form rewrite where sibling attributes do not).
  const value = typeof message === 'string' ? message : '';
  const trimmed = value.trim();
  let parsed = null;
  if (trimmed.startsWith('{')) {
    try { parsed = JSON.parse(trimmed); } catch (_) { parsed = null; }
  }

  if (parsed && typeof parsed === 'object') {
    OPTION_KEYS.forEach((key) => {
      if (parsed[key] != null) options[key] = String(parsed[key]);
    });
  } else if (value) {
    options.body = value;
  }

  // Sibling attributes are the more explicit statement, so they win.
  OPTION_KEYS.forEach((key) => {
    const attribute = `data-turbo-confirm-${key}`;
    for (const source of sources) {
      const holder = source.closest(`[${attribute}]`);
      if (holder) {
        options[key] = holder.getAttribute(attribute);
        break;
      }
    }
  });

  return options;
};

// What a plain-text confirm should say. The raw `data-turbo-confirm` value can
// be the `modal_confirm` helper's JSON payload, which is not something to put
// in front of a user, so the parsed message wins over it.
const confirmText = (options, message) => options.body || options.title || message || '';

const nativeConfirm = (options, message) => window.confirm(confirmText(options, message));

// Present only when the layout rendered `modal_confirm_template` -- this is the
// feature's on switch, looked up per confirmation so a Turbo Drive navigation
// into (or out of) a layout that renders it takes effect immediately.
const confirmTemplate = () => document.getElementById(TEMPLATE_ID);

const buildDialog = (options) => {
  const dialog = confirmTemplate()?.content?.querySelector('dialog')?.cloneNode(true);
  if (!dialog) return null;

  // Anything left unset keeps the server-rendered default from
  // `UltimateTurboModal.configure { |c| c.confirm ... }`.
  const fill = (selector, text) => {
    const element = dialog.querySelector(selector);
    if (element && text != null) element.textContent = text;
    return element;
  };

  fill('#modal-title-h-confirm', options.title);
  fill('[data-utmr-confirm-action="accept"]', options.accept);
  fill('[data-utmr-confirm-action="cancel"]', options.cancel);

  const body = fill('#modal-body-confirm', options.body);
  if (body && !body.textContent) {
    // Title-only confirm: drop the empty body and the padded wrapper it sits
    // in, so the buttons sit the same distance below the title as they would
    // below a message. Also stop aria-describedby pointing at nothing.
    (dialog.querySelector('#modal-main-confirm') || body).remove();
    dialog.removeAttribute('aria-describedby');
  }

  if (options.variant) dialog.dataset.utmrConfirmVariant = options.variant;

  return dialog;
};

// Which button should be under the user's fingers when the dialog lands. For a
// destructive action that is the safe one.
//
// This is the only thing that sets initial focus; the markup carries no
// `autofocus`. Focus has to wait for the enter transition to be armed: flavors
// that keep the dialog's contents `visibility: hidden` until `data-entered`
// (the vanilla one does) have nothing focusable at showModal() time, so an
// early .focus() is silently dropped and the dialog element keeps focus.
const focusInitialButton = (dialog, options) => {
  const action = options.variant === 'danger' ? 'cancel' : 'accept';
  const target = dialog.querySelector(`[data-utmr-confirm-action="${action}"]`);
  if (!target) return;

  if (dialog.hasAttribute('data-entered')) {
    target.focus();
    return;
  }

  let settled = false;
  let observer = null;
  const settle = () => {
    if (settled) return;
    settled = true;
    observer?.disconnect();
    clearTimeout(timer);
    target.focus();
  };
  // Generous enough to outlast the enter transition, short enough that a
  // flavor with no transition at all still focuses promptly.
  const timer = setTimeout(settle, 400);
  observer = new MutationObserver(() => {
    if (dialog.hasAttribute('data-entered')) settle();
  });
  observer.observe(dialog, { attributes: true, attributeFilter: ['data-entered'] });
};

const showConfirm = (options, message) => new Promise((resolve) => {
  const dialog = buildDialog(options);
  if (!dialog) {
    // The template is on the page but holds no <dialog>, which means it was
    // overridden with something unexpected.
    console.warn(`[UltimateTurboModal] #${TEMPLATE_ID} contains no <dialog>, falling back to window.confirm.`);
    resolve(nativeConfirm(options, message));
    return;
  }

  let settled = false;
  let accepted = false;

  const finish = (value) => {
    if (settled) return;
    settled = true;
    document.removeEventListener('turbo:before-cache', onBeforeCache);
    resolve(value);
  };

  // The page is being cached for a navigation; the dialog goes with it.
  const onBeforeCache = () => finish(false);
  document.addEventListener('turbo:before-cache', onBeforeCache);

  // Every dismissal that isn't the accept button -- Escape, the Cancel button,
  // browser back -- lands here with accepted false.
  dialog.addEventListener('modal:closed', () => finish(accepted));

  dialog.querySelectorAll('[data-utmr-confirm-action]').forEach((button) => {
    button.addEventListener('click', (event) => {
      event.preventDefault();
      accepted = button.dataset.utmrConfirmAction === 'accept';
      const controller = dialog.__ultimateTurboModalController;
      if (controller) {
        // Resolve only once the leave animation is done, so the request never
        // fires with the confirm still on screen. hideModalWithPromise also
        // settles if the close is vetoed or the controller disconnects.
        controller.hideModalWithPromise({ skipHistoryBack: true }).then(() => finish(accepted));
      } else {
        dialog.remove();
        finish(accepted);
      }
    });
  });

  document.body.appendChild(dialog);

  requestAnimationFrame(() => {
    if (settled) return;

    if (!dialog.__ultimateTurboModalController) {
      // Stimulus never connected, so the dialog would sit in the DOM closed
      // and the promise would never settle.
      console.warn(
        '[UltimateTurboModal] The "modal" Stimulus controller is not registered, ' +
        'falling back to window.confirm.'
      );
      dialog.remove();
      finish(nativeConfirm(options, message));
      return;
    }

    focusInitialButton(dialog, options);
  });
});

const handler = (message, formElement, submitter) => {
  const sources = optionSources(formElement, submitter);
  const options = readOptions(message, sources);

  // No template means the app never opted in, so this confirmation is not ours
  // to handle. Same for a single element opting back out: through the payload
  // on a link (`modal_confirm(native: true)`), or through the attribute on a
  // form or submitter, where sibling attributes survive.
  const optedOut = !confirmTemplate() ||
    options.native === 'true' ||
    sources.some((source) => source.closest('[data-turbo-confirm-native]'));

  if (optedOut) {
    // Whatever handles this instead still gets readable text, never the payload.
    return previousConfirm
      ? previousConfirm(confirmText(options, message), formElement, submitter)
      : Promise.resolve(nativeConfirm(options, message));
  }

  return showConfirm(options, message);
};

/**
 * Take over Turbo's confirm hook. Called automatically when this package is
 * imported, so apps normally never call it -- rendering
 * `modal_confirm_template` in the layout is the whole opt-in.
 *
 * Only worth calling by hand when something else assigns
 * `Turbo.config.forms.confirm` after UTMR loads and you want the dialog back.
 */
export function enableModalConfirm() {
  const turbo = window.Turbo;
  if (!turbo) {
    console.warn('[UltimateTurboModal] window.Turbo is not available; Turbo Confirm support is off.');
    return;
  }

  // Capture whatever the app had installed before we take the single global
  // slot, so `data-turbo-confirm-native` can still defer to it.
  if (!installed) {
    const existing = turbo.config?.forms?.confirm;
    previousConfirm = typeof existing === 'function' ? existing : null;
  }
  installed = true;

  if (turbo.config?.forms) {
    turbo.config.forms.confirm = handler;
  } else if (typeof turbo.setConfirmMethod === 'function') {
    turbo.setConfirmMethod(handler);
  } else {
    console.warn('[UltimateTurboModal] This version of Turbo has no confirm hook; Turbo Confirm support is off.');
  }
}
