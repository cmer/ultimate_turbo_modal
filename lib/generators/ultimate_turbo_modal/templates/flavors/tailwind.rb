# frozen_string_literal: true

# Tailwind CSS v4
module UltimateTurboModal::Flavors
  class Tailwind < UltimateTurboModal::Base
    # Modal constants

    DIALOG_CLASSES = [
      "group",
      # Dialog reset
      "fixed inset-0 p-0 m-0 border-none bg-transparent",
      "max-w-[100vw] max-h-dvh w-full h-full overflow-y-auto",
      # Backdrop
      "backdrop:bg-gray-900/70 dark:backdrop:bg-gray-900/80",
      "backdrop:opacity-0 backdrop:transition-opacity backdrop:duration-300 backdrop:ease-out",
      "data-[entered]:backdrop:opacity-100",
      "data-[closing]:backdrop:duration-200 data-[closing]:backdrop:ease-in"
    ].join(" ")

    DIV_INNER_CLASSES = [
      "flex min-h-full items-start justify-center pt-[10vh] sm:p-4",
      # Hidden before animation starts
      "group-[&:not([data-enter-ready]):not([data-entered])]:invisible",
      # Transition
      "transition duration-300 ease-out",
      "group-data-[closing]:duration-200 group-data-[closing]:ease-in",
      # Default state (closed): faded + shifted
      "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
      # Entered state
      "group-data-[entered]:opacity-100 group-data-[entered]:translate-y-0 group-data-[entered]:scale-100"
    ].join(" ")

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

    DRAWER_DIALOG_CLASSES = [
      "group",
      # Dialog reset
      "fixed inset-0 p-0 m-0 border-none bg-transparent",
      "max-w-[100vw] max-h-dvh w-full h-full overflow-y-auto",
      # Backdrop (only when overlay enabled)
      "data-[overlay=true]:backdrop:bg-gray-900/70 dark:data-[overlay=true]:backdrop:bg-gray-900/80",
      "backdrop:opacity-0 backdrop:transition-opacity backdrop:duration-300 backdrop:ease-out",
      "data-[entered]:data-[overlay=true]:backdrop:opacity-100",
      "data-[overlay=false]:backdrop:bg-transparent",
      "data-[closing]:backdrop:duration-200 data-[closing]:backdrop:ease-in",
      # Responsive gutter
      "[--utmr-gutter:2.5rem] sm:[--utmr-gutter:4rem]",
      # Drawer sizes via data attribute
      "data-[drawer-size=sm]:[--utmr-w:24rem]",
      "data-[drawer-size=md]:[--utmr-w:28rem]",
      "data-[drawer-size=lg]:[--utmr-w:42rem]",
      "data-[drawer-size=xl]:[--utmr-w:56rem]",
      "data-[drawer-size=full]:[--utmr-w:100vw]",
      # Drawer direction → hidden translate
      "data-[drawer=left]:[--utmr-hide:-100%_0]",
      "data-[drawer=right]:[--utmr-hide:100%_0]"
    ].join(" ")

    DRAWER_WRAPPER_CLASSES = [
      "absolute inset-0 overflow-hidden"
    ].join(" ")

    DRAWER_PANEL_CLASSES = [
      "absolute inset-y-0",
      # Position based on direction
      "group-data-[drawer=left]:left-0 group-data-[drawer=right]:right-0",
      # Width (size variable + gutter)
      "w-[min(var(--utmr-w),calc(100vw_-_var(--utmr-gutter)))]",
      # Default: translated off-screen
      "[translate:var(--utmr-hide)]",
      # Entered: in place
      "group-data-[entered]:[translate:0]",
      # Closing: back off-screen
      "group-data-[closing]:[translate:var(--utmr-hide)]",
      # Transition
      "transition-[translate] duration-500 ease-in-out sm:duration-700",
      "will-change-[translate]",
      # Hidden before animation ready
      "group-[&:not([data-enter-ready]):not([data-entered])]:invisible"
    ].join(" ")

    DRAWER_CONTENT_CLASSES = [
      "relative flex h-full w-full flex-col bg-white group-data-[padding=true]:py-6 shadow-xl dark:bg-gray-800 dark:text-white"
    ].join(" ")

    DRAWER_HEADER_CLASSES = "flex items-start justify-between w-full px-4 sm:px-6 group-data-[header-divider=true]:border-b group-data-[header=false]:hidden"
    DRAWER_TITLE_CLASSES = ""
    DRAWER_TITLE_H_CLASSES = "group-data-[title=false]:hidden text-base font-semibold text-gray-900 dark:text-white"
    DRAWER_MAIN_CLASSES = "relative group-data-[padding=true]:mt-6 flex-1 overflow-y-auto group-data-[padding=true]:px-4 group-data-[padding=true]:sm:px-6"
    DRAWER_FOOTER_CLASSES = "flex shrink-0 px-4 py-4 sm:px-6 group-data-[footer-divider=true]:border-t group-data-[footer-divider=true]:border-gray-200 dark:group-data-[footer-divider=true]:border-gray-600"
    DRAWER_CLOSE_CLASSES = "ml-3 flex h-7 items-center group-data-[close-button=false]:hidden"
    DRAWER_CLOSE_BUTTON_CLASSES = "relative rounded-md text-gray-400 hover:text-gray-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
    DRAWER_CLOSE_SR_CLASSES = "sr-only"
    DRAWER_CLOSE_ICON_CLASSES = "size-6"
  end
end
