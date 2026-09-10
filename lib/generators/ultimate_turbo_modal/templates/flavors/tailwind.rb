# frozen_string_literal: true

# Tailwind CSS v4
#
# Group selectors are scoped with the named groups `group/utmr-modal` and
# `group/utmr-drawer` so that when a modal stacks on top of an open drawer,
# the inner modal's transition styles don't pick up the outer drawer's
# `data-entered` state (which would prevent the modal from animating out).
module UltimateTurboModal::Flavors
  class Tailwind < UltimateTurboModal::Base
    STYLES = "html:has(dialog.utmr[open]) { overflow: hidden; }"

    # Modal constants

    MODAL_DIALOG_CLASSES = [
      "group/utmr-modal",
      # Dialog reset
      "fixed inset-0 p-0 m-0 border-none bg-transparent",
      "max-w-[100vw] max-h-dvh w-full h-full overflow-y-auto",
      # Backdrop (only when overlay enabled)
      "data-[overlay=true]:backdrop:bg-gray-900/70 dark:data-[overlay=true]:backdrop:bg-gray-900/80",
      "backdrop:opacity-0 backdrop:transition-opacity backdrop:duration-300 backdrop:ease-out",
      "data-[entered]:data-[overlay=true]:backdrop:opacity-100",
      "data-[overlay=false]:backdrop:bg-transparent",
      "data-[closing]:backdrop:duration-200 data-[closing]:backdrop:ease-in"
    ].join(" ")

    # The enter/leave animation, shared by the modal and the confirm dialog.
    # Tailwind resolves conflicts by CSS source order rather than by the order
    # classes appear in the string, so the two cannot share a layout line -- but
    # they must not drift apart on the animation.
    MODAL_TRANSITION_CLASSES = [
      "transition duration-300 ease-out",
      "group-data-[closing]/utmr-modal:duration-200 group-data-[closing]/utmr-modal:ease-in",
      # Default state (closed): faded + shifted
      "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
      # Entered state
      "group-data-[entered]/utmr-modal:opacity-100 group-data-[entered]/utmr-modal:translate-y-0 group-data-[entered]/utmr-modal:scale-100"
    ].join(" ")

    MODAL_INNER_CLASSES = [
      "flex min-h-full items-start justify-center pt-[10vh] sm:items-center sm:pt-0 sm:p-4 sm:pb-[10vh]",
      MODAL_TRANSITION_CLASSES
    ].join(" ")

    MODAL_CONTENT_CLASSES = "relative transform max-h-screen overflow-hidden rounded-lg bg-white text-left shadow-lg transition-all sm:max-w-3xl dark:bg-gray-800 dark:text-white"
    MODAL_MAIN_CLASSES = "group-data-[padding=true]/utmr-modal:p-4 group-data-[padding=true]/utmr-modal:pt-2 overflow-y-auto max-h-[75vh]"
    MODAL_HEADER_CLASSES = "flex justify-between items-center w-full py-4 rounded-t dark:border-gray-600 group-data-[header-divider=true]/utmr-modal:border-b group-data-[header=false]/utmr-modal:absolute"
    MODAL_TITLE_CLASSES = "pl-4"
    MODAL_TITLE_H_CLASSES = "group-data-[title=false]/utmr-modal:hidden text-lg font-semibold text-gray-900 dark:text-white"
    MODAL_FOOTER_CLASSES = "flex p-4 rounded-b dark:border-gray-600 group-data-[footer-divider=true]/utmr-modal:border-t"
    MODAL_CLOSE_CLASSES = "mr-4 group-data-[close-button=false]/utmr-modal:hidden"
    MODAL_CLOSE_SR_CLASSES = "sr-only"
    MODAL_CLOSE_BUTTON_CLASSES = "text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
    MODAL_CLOSE_ICON_CLASSES = "w-5 h-5"

    # Confirm dialog constants
    #
    # The confirm dialog renders through the modal's markup, so it inherits the
    # dialog, backdrop and transition classes above. These constants only
    # narrow the card and retune the spacing for what is a short prompt rather
    # than a page of content. Any slot left undefined falls back to MODAL_*.

    # Same transition as a modal, with a real gutter so the full-width card
    # never touches the screen edge on mobile.
    CONFIRM_INNER_CLASSES = [
      "flex min-h-full items-start justify-center p-4 pt-[10vh] sm:items-center sm:pt-4 sm:pb-[10vh]",
      MODAL_TRANSITION_CLASSES
    ].join(" ")

    # Sized rather than shrink-to-fit, so a one-word prompt and a three-line one
    # come out the same. The floor is written as `min(20rem, 100%)` so it can
    # never push the card wider than the space it has on a narrow screen.
    CONFIRM_CONTENT_CLASSES = [
      "relative w-full transform overflow-hidden rounded-lg text-left shadow-xl transition-all",
      "min-w-[min(20rem,100%)] sm:max-w-md",
      "bg-white dark:bg-gray-800 dark:text-white"
    ].join(" ")

    CONFIRM_HEADER_CLASSES = [
      "flex items-start justify-between gap-4 w-full px-6 pt-6",
      "dark:border-gray-600",
      "group-data-[header-divider=true]/utmr-modal:border-b group-data-[header-divider=true]/utmr-modal:pb-4",
      "group-data-[header=false]/utmr-modal:hidden"
    ].join(" ")

    CONFIRM_TITLE_CLASSES = "min-w-0"
    CONFIRM_TITLE_H_CLASSES = "group-data-[title=false]/utmr-modal:hidden text-base font-semibold text-gray-900 dark:text-white"

    CONFIRM_MAIN_CLASSES = "group-data-[padding=true]/utmr-modal:px-6 group-data-[padding=true]/utmr-modal:pt-2"
    CONFIRM_BODY_CLASSES = "text-sm/6 text-gray-500 dark:text-gray-400"

    CONFIRM_FOOTER_CLASSES = [
      "px-6 pt-6 pb-6",
      "dark:border-gray-600 group-data-[footer-divider=true]/utmr-modal:border-t"
    ].join(" ")

    # Stacked and full-width on mobile (thumb-friendly), inline and right
    # aligned from `sm` up. Reversed so the primary action sits on top.
    CONFIRM_ACTIONS_CLASSES = "flex w-full flex-col-reverse gap-2 sm:flex-row sm:justify-end sm:gap-3"

    CONFIRM_BUTTON_CLASSES = [
      "inline-flex w-full sm:w-auto justify-center items-center rounded-md",
      "px-4 py-2.5 sm:py-2 text-sm font-semibold transition-colors",
      "focus-visible:outline-2 focus-visible:outline-offset-2"
    ].join(" ")

    CONFIRM_CANCEL_CLASSES = [
      CONFIRM_BUTTON_CLASSES,
      "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
      "dark:bg-gray-700 dark:text-gray-100 dark:ring-gray-600 dark:hover:bg-gray-600",
      "focus-visible:outline-gray-400"
    ].join(" ")

    CONFIRM_ACCEPT_CLASSES = [
      CONFIRM_BUTTON_CLASSES,
      "text-white shadow-sm bg-indigo-600 hover:bg-indigo-500 focus-visible:outline-indigo-600",
      # Destructive variant, set from `variant: :danger`
      "group-data-[utmr-confirm-variant=danger]/utmr-modal:bg-red-600",
      "group-data-[utmr-confirm-variant=danger]/utmr-modal:hover:bg-red-500",
      "group-data-[utmr-confirm-variant=danger]/utmr-modal:focus-visible:outline-red-600"
    ].join(" ")

    # Drawer constants

    DRAWER_DIALOG_CLASSES = [
      "group/utmr-drawer",
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
      "data-[drawer-size=xs]:[--utmr-w:16rem]",
      "data-[drawer-size=sm]:[--utmr-w:20rem]",
      "data-[drawer-size=md]:[--utmr-w:24rem]",
      "data-[drawer-size=lg]:[--utmr-w:28rem]",
      "data-[drawer-size=xl]:[--utmr-w:42rem]",
      "data-[drawer-size=2xl]:[--utmr-w:56rem]",
      "data-[drawer-size=full]:[--utmr-w:100vw]",
      # Drawer direction → hidden translate
      "data-[drawer=left]:[--utmr-hide:-100%_0]",
      "data-[drawer=right]:[--utmr-hide:100%_0]"
    ].join(" ")

    DRAWER_WRAPPER_CLASSES = "absolute inset-0 overflow-hidden"

    DRAWER_PANEL_CLASSES = [
      "absolute inset-y-0",
      # Position based on direction
      "group-data-[drawer=left]/utmr-drawer:left-0 group-data-[drawer=right]/utmr-drawer:right-0",
      # Width (size variable + gutter)
      "w-[min(var(--utmr-w),calc(100vw_-_var(--utmr-gutter)))]",
      # Default: translated off-screen
      "[translate:var(--utmr-hide)]",
      # Entered: in place
      "group-data-[entered]/utmr-drawer:[translate:0]",
      # Closing: back off-screen
      "group-data-[closing]/utmr-drawer:[translate:var(--utmr-hide)]",
      # Transition
      "transition-[translate] duration-250 ease-in-out sm:duration-400",
      "will-change-[translate]",
      # Hidden before animation ready
      "group-[&:not([data-enter-ready]):not([data-entered])]/utmr-drawer:invisible"
    ].join(" ")

    DRAWER_CONTENT_CLASSES = "relative flex h-full w-full flex-col bg-white group-data-[padding=true]/utmr-drawer:pt-6 shadow-xl dark:bg-gray-800 dark:text-white"

    DRAWER_HEADER_CLASSES = "flex items-start justify-between w-full px-4 sm:px-6 group-data-[header-divider=true]/utmr-drawer:pb-4 group-data-[header-divider=true]/utmr-drawer:border-b group-data-[header-divider=true]/utmr-drawer:border-gray-200 dark:group-data-[header-divider=true]/utmr-drawer:border-gray-600 group-data-[header=false]/utmr-drawer:hidden"
    DRAWER_TITLE_CLASSES = ""
    DRAWER_TITLE_H_CLASSES = "group-data-[title=false]/utmr-drawer:hidden text-base font-semibold text-gray-900 dark:text-white"
    DRAWER_MAIN_CLASSES = "relative group-data-[padding=true]/utmr-drawer:mt-6 flex-1 overflow-y-auto group-data-[padding=true]/utmr-drawer:px-4 group-data-[padding=true]/utmr-drawer:sm:px-6 group-data-[padding=true]/utmr-drawer:pb-6"
    DRAWER_FOOTER_CLASSES = "flex shrink-0 px-4 py-4 sm:px-6 group-data-[footer-divider=true]/utmr-drawer:border-t group-data-[footer-divider=true]/utmr-drawer:border-gray-200 dark:group-data-[footer-divider=true]/utmr-drawer:border-gray-600"
    DRAWER_CLOSE_CLASSES = "ml-3 flex h-7 items-center group-data-[close-button=false]/utmr-drawer:hidden"
    DRAWER_CLOSE_BUTTON_CLASSES = "relative rounded-md text-gray-400 hover:text-gray-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
    DRAWER_CLOSE_SR_CLASSES = MODAL_CLOSE_SR_CLASSES
    DRAWER_CLOSE_ICON_CLASSES = "size-6"
  end
end
