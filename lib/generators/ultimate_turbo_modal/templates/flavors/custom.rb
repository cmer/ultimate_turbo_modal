# frozen_string_literal: true

# Custom
# TODO: define the classes for each HTML element.
module UltimateTurboModal::Flavors
  class Custom < UltimateTurboModal::Base
    DIV_MODAL_CONTAINER_CLASSES = ""
    DIV_OVERLAY_CLASSES = ""
    DIV_DIALOG_CLASSES = ""
    DIV_INNER_CLASSES = ""
    DIV_CONTENT_CLASSES = ""
    DIV_MAIN_CLASSES = ""
    DIV_HEADER_CLASSES = ""
    DIV_TITLE_CLASSES = ""
    DIV_TITLE_H_CLASSES = ""
    DIV_FOOTER_CLASSES = ""
    BUTTON_CLOSE_CLASSES = ""
    BUTTON_CLOSE_SR_ONLY_CLASSES = ""
    CLOSE_BUTTON_TAG_CLASSES = ""
    ICON_CLOSE_CLASSES = ""

    TRANSITIONS = {
      overlay: {
        enter: {
          animation: "",
          start: "",
          end: ""
        },
        leave: {
          animation: "",
          start: "",
          end: ""
        }
      },
      dialog: {
        enter: {
          animation: "",
          start: "",
          end: ""
        },
        leave: {
          animation: "",
          start: "",
          end: ""
        }
      }
    }
  end
end
