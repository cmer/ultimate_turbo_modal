# frozen_string_literal: true

# Custom
# TODO: define the classes for each HTML element.
#
# STYLES: Optional CSS string injected as an inline <style> tag inside the dialog.
# Use this for @keyframes, transitions, or any CSS that can't be expressed as classes.
# Set to "" or omit entirely if you handle all styling via classes and external CSS.
module UltimateTurboModal::Flavors
  class Custom < UltimateTurboModal::Base
    STYLES = "html:has(dialog.utmr[open]) { overflow: hidden; }"

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

    # Confirm dialog constants
    # Only the slots that have no modal equivalent are listed. Every other slot
    # (dialog, inner, content, header, title, main, footer) falls back to the
    # matching MODAL_* class above; define a CONFIRM_* one to override it.
    CONFIRM_BODY_CLASSES = ""
    CONFIRM_ACTIONS_CLASSES = ""
    CONFIRM_CANCEL_CLASSES = ""
    CONFIRM_ACCEPT_CLASSES = ""

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
