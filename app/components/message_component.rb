# frozen_string_literal: true

class MessageComponent < ViewComponent::Base
  attr_reader :message

  def initialize(message:)
    @message = message
  end
end
