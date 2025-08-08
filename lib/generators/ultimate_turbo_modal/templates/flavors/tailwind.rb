# frozen_string_literal: true

# Tailwind CSS v4
module UltimateTurboModal::Flavors
  class Tailwind < UltimateTurboModal::Base
    DIV_MODAL_CONTAINER_CLASSES = "relative group z-50"
    DIV_OVERLAY_CLASSES = "fixed inset-0 bg-gray-900/70 transition-opacity dark:bg-gray-900/80 opacity-0"
    DIV_DIALOG_CLASSES = "fixed inset-0 overflow-y-auto sm:max-w-[80%] md:max-w-3xl sm:mx-auto m-4 opacity-0"
    DIV_INNER_CLASSES = "flex min-h-full items-start justify-center pt-[10vh] sm:p-4"
    DIV_CONTENT_CLASSES = "relative transform max-h-screen overflow-hidden rounded-lg bg-white text-left shadow-lg transition-all sm:my-8 sm:max-w-3xl dark:bg-gray-800 dark:text-white"
    DIV_MAIN_CLASSES = "group-data-[padding=true]:p-4 group-data-[padding=true]:pt-2 overflow-y-auto max-h-[75vh]"
    DIV_HEADER_CLASSES = "flex justify-between items-center w-full py-4 rounded-t dark:border-gray-600 group-data-[header-divider=true]:border-b group-data-[header=false]:absolute"
    DIV_TITLE_CLASSES = "pl-4"
    DIV_TITLE_H_CLASSES = "group-data-[title=false]:hidden text-lg font-semibold text-gray-900 dark:text-white"
    DIV_FOOTER_CLASSES = "flex p-4 rounded-b dark:border-gray-600 group-data-[footer-divider=true]:border-t"
    BUTTON_CLOSE_CLASSES = "mr-4 group-data-[close-button=false]:hidden"
    BUTTON_CLOSE_SR_ONLY_CLASSES = "sr-only"
    CLOSE_BUTTON_TAG_CLASSES = "text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
    ICON_CLOSE_CLASSES = "w-5 h-5"

    TRANSITIONS = {
      overlay: {
        enter: {
          animation: "ease-out duration-300",
          start: "opacity-0",
          end: "opacity-100"
        },
        leave: {
          animation: "ease-in duration-200",
          start: "opacity-100",
          end: "opacity-0"
        }
      },
      dialog: {
        enter: {
          animation: "ease-out duration-300",
          start: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
          end: "opacity-100 translate-y-0 sm:scale-100"
        },
        leave: {
          animation: "ease-in duration-200",
          start: "opacity-100 translate-y-0 sm:scale-100",
          end: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
        }
      }
    }
  end
end
