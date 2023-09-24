# frozen_string_literal: true

require "capybara/rails"
require "capybara-screenshot/rspec"

require_relative "capybara/rack_test"

Capybara.server = :puma, { Silent: true }
Capybara.drivers[:chrome] = Capybara.drivers[:selenium_chrome]
Capybara.drivers[:firefox] = Capybara.drivers[:selenium]
Capybara.save_path = ENV.fetch("CIRCLE_ARTIFACTS", Capybara.save_path)

driver = ENV.fetch("DRIVER").to_sym if ENV.key?("DRIVER")

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by(driver || :rack_test)
  end

  config.before(:each, :js, type: :system) do
    driven_by(driver || :selenium_headless)
  end
end
