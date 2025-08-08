# frozen_string_literal: true

# Vanilla CSS
module UltimateTurboModal::Flavors
  class Vanilla < UltimateTurboModal::Base
    DIV_MODAL_CONTAINER_CLASSES = "modal-container"
    # Include enter-start classes so initial paint is hidden and transitions can animate smoothly
    DIV_OVERLAY_CLASSES = "modal-overlay modal-transition-overlay-enter-start"
    DIV_DIALOG_CLASSES = "modal-outer modal-transition-dialog-enter-start"
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
          animation: "modal-transition-overlay-enter-animation",
          start: "modal-transition-overlay-enter-start",
          end: "modal-transition-overlay-enter-end"
        },
        leave: {
          animation: "modal-transition-overlay-leave-animation",
          start: "modal-transition-overlay-leave-start",
          end: "modal-transition-overlay-leave-end"
        }
      },
      dialog: {
        enter: {
          animation: "modal-transition-dialog-enter-animation",
          start: "modal-transition-dialog-enter-start",
          end: "modal-transition-dialog-enter-end"
        },
        leave: {
          animation: "modal-transition-dialog-leave-animation",
          start: "modal-transition-dialog-leave-start",
          end: "modal-transition-dialog-leave-end"
        }
      }
    }
  end
end
