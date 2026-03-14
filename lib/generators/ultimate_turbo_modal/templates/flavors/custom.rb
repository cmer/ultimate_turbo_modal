# frozen_string_literal: true

# Custom
# TODO: define the classes for each HTML element.
#
# STYLES: Optional CSS string injected as an inline <style> tag inside the dialog.
# Use this for @keyframes, transitions, or any CSS that can't be expressed as classes.
# Set to "" or omit entirely if you handle all styling via classes and external CSS.
module UltimateTurboModal::Flavors
  class Custom < UltimateTurboModal::Base
    STYLES = ""

    MODAL_DIALOG_CLASSES = ""
    MODAL_INNER_CLASSES = ""
    MODAL_CONTENT_CLASSES = ""
    MODAL_MAIN_CLASSES = ""
    MODAL_HEADER_CLASSES = ""
    MODAL_TITLE_CLASSES = ""
    MODAL_TITLE_H_CLASSES = ""
    MODAL_FOOTER_CLASSES = ""
    MODAL_CLOSE_CLASSES = ""
    MODAL_CLOSE_BUTTON_CLASSES = ""
    MODAL_CLOSE_SR_CLASSES = ""
    MODAL_CLOSE_ICON_CLASSES = ""

    # Drawer constants
    DRAWER_DIALOG_CLASSES = MODAL_DIALOG_CLASSES
    DRAWER_WRAPPER_CLASSES = ""
    DRAWER_PANEL_CLASSES = ""
    DRAWER_CONTENT_CLASSES = MODAL_CONTENT_CLASSES
    DRAWER_HEADER_CLASSES = MODAL_HEADER_CLASSES
    DRAWER_TITLE_CLASSES = MODAL_TITLE_CLASSES
    DRAWER_TITLE_H_CLASSES = MODAL_TITLE_H_CLASSES
    DRAWER_MAIN_CLASSES = MODAL_MAIN_CLASSES
    DRAWER_FOOTER_CLASSES = MODAL_FOOTER_CLASSES
    DRAWER_CLOSE_CLASSES = MODAL_CLOSE_CLASSES
    DRAWER_CLOSE_HIT_AREA_CLASSES = ""
    DRAWER_CLOSE_BUTTON_CLASSES = MODAL_CLOSE_BUTTON_CLASSES
    DRAWER_CLOSE_SR_CLASSES = MODAL_CLOSE_SR_CLASSES
    DRAWER_CLOSE_ICON_CLASSES = MODAL_CLOSE_ICON_CLASSES
  end
end
