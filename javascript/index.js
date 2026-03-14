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

// Escape modal when the target frame is missing from the response.
// This handles both redirects and regular links (e.g., <a href="/">) clicked
// inside the modal/drawer — the response won't contain the modal frame,
// so we escape to a full-page Turbo visit.
const handleTurboFrameMissing = (event) => {
  if (isModalFrameTarget(event)) {
    event.preventDefault()
    window.modal?.hide()
    event.detail.visit(event.detail.response)
  }
};

// Morph the innerHTML of the modal to prevent flickering and transition animations
const handleTurboBeforeFrameRender = (event) => {
  if (isModalFrameTarget(event)) {
    event.detail.render = (currentElement, newElement) => {
      Idiomorph.morph(currentElement, newElement, {
        morphstyle: 'innerHTML'
      })
    }
  }
};

document.removeEventListener("turbo:frame-missing", handleTurboFrameMissing);
document.addEventListener("turbo:frame-missing", handleTurboFrameMissing);

document.removeEventListener("turbo:before-frame-render", handleTurboBeforeFrameRender);
document.addEventListener("turbo:before-frame-render", handleTurboBeforeFrameRender);

export { UltimateTurboModalController };
