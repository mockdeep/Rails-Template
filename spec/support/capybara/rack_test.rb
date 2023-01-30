# frozen_string_literal: true

module Capybara
  module RackTest
    class Driver < Capybara::Driver::Base
      def accept_modal(_type, text: nil, **_options)
        escaped_text = Capybara::Selector::CSS.escape(text)
        if browser.find(:css, "[data-confirm='#{escaped_text}']").none?
          raise Capybara::ElementNotFound,
                "Unable to find modal with text \"#{text}\""
        end

        yield
      end
    end
  end
end
