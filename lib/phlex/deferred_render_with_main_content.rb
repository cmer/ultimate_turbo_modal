# frozen_string_literal: true

module Phlex
  module DeferredRenderWithMainContent
    def view_template(&block)
      output = capture(&block)
      super { raw_html(output) }
    end
  end
end
