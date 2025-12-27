# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start("rails")
  SimpleCov.minimum_coverage(100)
end

