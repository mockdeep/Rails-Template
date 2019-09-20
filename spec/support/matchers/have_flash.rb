# frozen_string_literal: true

module Matchers
  class HaveFlash
    attr_reader :expected_type, :expected_message, :actual

    def initialize(expected_type, expected_message)
      @expected_type = expected_type
      @expected_message = expected_message
    end

    def matches?(actual)
      @actual = actual

      actual.has_selector?(expected_selector, text: expected_message)
    end

    def failure_message
      <<~MESSAGE.squish
        expected to find #{expected_type} flash with text '#{expected_message}'
        but found #{actual.all("[class^='flash-']").map(&:text)}
      MESSAGE
    end

    private

    def expected_selector
      ".flash-#{expected_type}"
    end
  end
end
