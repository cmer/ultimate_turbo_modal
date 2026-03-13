# frozen_string_literal: true

# Tailwind CSS v4
module UltimateTurboModal::Flavors
  class Tailwind < UltimateTurboModal::Base
    DIALOG_CLASSES = "group backdrop:bg-gray-900/70 dark:backdrop:bg-gray-900/80"
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

    # Drawer constants
    DRAWER_DIALOG_CLASSES = "group data-[overlay=true]:backdrop:bg-gray-900/70 dark:data-[overlay=true]:backdrop:bg-gray-900/80"

    DRAWER_WRAPPER_CLASSES = [
      "absolute inset-0 overflow-hidden"
    ].join(" ")

    DRAWER_PANEL_CLASSES = [
      "absolute inset-y-0"
    ].join(" ")

    DRAWER_CONTENT_CLASSES = [
      "relative flex h-full w-full flex-col overflow-y-auto bg-white group-data-[padding=true]:py-6 shadow-xl dark:bg-gray-800 dark:text-white"
    ].join(" ")

    DRAWER_HEADER_CLASSES = "flex items-start justify-between w-full px-4 sm:px-6 group-data-[header-divider=true]:border-b group-data-[header=false]:hidden"
    DRAWER_TITLE_CLASSES = ""
    DRAWER_TITLE_H_CLASSES = "group-data-[title=false]:hidden text-base font-semibold text-gray-900 dark:text-white"
    DRAWER_MAIN_CLASSES = "relative group-data-[padding=true]:mt-6 flex-1 group-data-[padding=true]:px-4 group-data-[padding=true]:sm:px-6"
    DRAWER_FOOTER_CLASSES = "flex shrink-0 px-4 pt-6 sm:px-6 group-data-[footer-divider=true]:border-t group-data-[footer-divider=true]:border-gray-200 dark:group-data-[footer-divider=true]:border-gray-600"
    DRAWER_CLOSE_CLASSES = "ml-3 flex h-7 items-center group-data-[close-button=false]:hidden"
    DRAWER_CLOSE_BUTTON_CLASSES = "relative rounded-md text-gray-400 hover:text-gray-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
    DRAWER_CLOSE_SR_CLASSES = "sr-only"
    DRAWER_CLOSE_ICON_CLASSES = "size-6"
  end
end
