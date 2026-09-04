# Demonstrates the `close_on_submit` option and the per-form
# `data-modal-close-on-submit` override.
#
# The drawer variant is the scenario from issue #70: a chat composer that the
# user submits repeatedly, where dismissing the drawer after every message
# would be wrong. Messages live in the session so the demo needs no model.
class Testing::ChatsController < ApplicationController
  before_action :set_variant

  def show
  end

  def create_message
    body = params[:body].to_s.strip
    return head(:no_content) if body.blank?

    self.messages = messages + [{"body" => body, "at" => Time.current.strftime("%H:%M:%S")}]
  end

  def clear
    self.messages = []
  end

  private

  # `close_on_submit: false` is the interesting case, so make it the default
  # and let `?close_on_submit=1` opt back into the standard behavior.
  def set_variant
    @close_on_submit = params[:close_on_submit] == "1"
    @type = (params[:type] == "modal") ? "modal" : "drawer"
  end

  # Keep the demo variant in the form action URLs so re-rendered forms and
  # subsequent submissions stay on the same variant.
  def variant_params
    {type: @type, close_on_submit: @close_on_submit ? "1" : "0"}
  end

  def chat_messages_url = testing_chat_messages_path(variant_params)

  def chat_clear_url = testing_chat_clear_path(variant_params)
  helper_method :chat_messages_url, :chat_clear_url

  def messages
    session[:chat_messages] ||= []
  end

  def messages=(value)
    session[:chat_messages] = value
  end
  helper_method :messages
end
