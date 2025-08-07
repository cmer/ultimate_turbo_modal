# frozen_string_literal: true

# Vanilla CSS
module UltimateTurboModal::Flavors
  class Vanilla < UltimateTurboModal::Base
    DIV_MODAL_CONTAINER_CLASSES = "modal-container"
    DIV_OVERLAY_CLASSES = "modal-overlay"
    DIV_DIALOG_CLASSES = "modal-outer"
    DIV_INNER_CLASSES = "modal-inner"
    DIV_CONTENT_CLASSES = "modal-content"
    DIV_MAIN_CLASSES = "modal-main"
    DIV_HEADER_CLASSES = "modal-header"
    DIV_TITLE_CLASSES = "modal-title"
    DIV_TITLE_H_CLASSES = "modal-title-h"
    DIV_FOOTER_CLASSES = "modal-footer"
    BUTTON_CLOSE_CLASSES = "modal-close"
    BUTTON_CLOSE_SR_ONLY_CLASSES = "sr-only"
    CLOSE_BUTTON_TAG_CLASSES = "modal-close-button"
    ICON_CLOSE_CLASSES = "modal-close-icon"

    TRANSITIONS = {
      overlay: {
        enter: {
          animation: "fade-in 300ms ease-out",
          start: "fade-in-start",
          end: "fade-in-end"
        },
        leave: {
          animation: "fade-out 200ms ease-in",
          start: "fade-out-start",
          end: "fade-out-end"
        }
      },
      dialog: {
        enter: {
          animation: "slide-in 300ms ease-out",
          start: "slide-in-start",
          end: "slide-in-end"
        },
        leave: {
          animation: "slide-out 200ms ease-in",
          start: "slide-out-start",
          end: "slide-out-end"
        }
      }
    }
  end
end
