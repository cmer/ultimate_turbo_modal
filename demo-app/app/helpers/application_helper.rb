module ApplicationHelper
  def h1_classes
    "text-2xl font-bold tracking-tight text-gray-900 sm:text-4xl border-b mb-2 dark:text-white"
  end

  def button_classes
    "rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
  end

  def render_test_link(label, path)
    link_to label, path, data: {turbo_frame: "modal"}, class: "block px-4 py-2.5 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors"
  end
end
