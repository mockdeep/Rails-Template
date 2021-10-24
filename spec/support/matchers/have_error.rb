# frozen_string_literal: true

module Matchers
  class HaveError
    attr_reader :actual, :expected_message

    ERROR_SELECTOR = ".error-explanation li"

    def initialize(expected_message)
      @expected_message = expected_message
    end

    def matches?(actual)
      @actual = actual

      actual.has_selector?(ERROR_SELECTOR, text: expected_message)
    end

    def failure_message
      <<~MESSAGE.squish
        expected to find error with text #{expected_message} but found
        #{actual.all(ERROR_SELECTOR).map(&:text)}
      MESSAGE
    end
  end
end
