# frozen_string_literal: true

# Vanilla CSS
# All animation, transition, and structural CSS lives in vanilla.css.
# Set STYLES to a CSS string if you need additional inline styles.
module UltimateTurboModal::Flavors
  class Vanilla < UltimateTurboModal::Base
    STYLES = ""

    DIALOG_CLASSES = "modal-container"
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

    # Drawer constants
    DRAWER_DIALOG_CLASSES = "drawer-container"
    DRAWER_WRAPPER_CLASSES = "drawer-wrapper"
    DRAWER_PANEL_CLASSES = "drawer-panel"
    DRAWER_CONTENT_CLASSES = "drawer-content"
    DRAWER_HEADER_CLASSES = "drawer-header"
    DRAWER_TITLE_CLASSES = "drawer-title"
    DRAWER_TITLE_H_CLASSES = "drawer-title-h"
    DRAWER_MAIN_CLASSES = "drawer-main"
    DRAWER_FOOTER_CLASSES = "drawer-footer"
    DRAWER_CLOSE_CLASSES = "drawer-close"
    DRAWER_CLOSE_BUTTON_CLASSES = "drawer-close-button"
    DRAWER_CLOSE_SR_CLASSES = "sr-only"
    DRAWER_CLOSE_ICON_CLASSES = "drawer-close-icon"
  end
end
