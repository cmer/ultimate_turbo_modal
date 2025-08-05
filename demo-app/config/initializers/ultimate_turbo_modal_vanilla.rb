# frozen_string_literal: true

# Vanilla CSS
module UltimateTurboModal::Flavors
  class Vanilla < UltimateTurboModal::Base
    DIV_DIALOG_CLASSES = "modal-container"
    DIV_OVERLAY_CLASSES = "modal-overlay"
    DIV_OUTER_CLASSES = "modal-outer"
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
  end
end
