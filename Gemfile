# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read("./.ruby-version").strip

gem "rails", "~> 7.0.0"

gem "bcrypt"
gem "bootsnap", require: false
gem "haml-rails"
gem "pg"
gem "pry-rails"
gem "puma", "~> 6.0"
gem "sass-rails"
gem "sidekiq"
gem "strong_migrations"
gem "turbolinks"
gem "webpacker"
# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

group :development, :test do
  gem "bundler-audit"
  gem "byebug"
  gem "faker"
  gem "pry-byebug"
  gem "rspec-rails"
end

group :development do
  gem "brakeman", require: false
  gem "guard", require: false
  gem "guard-haml_lint", require: false
  gem "guard-rspec", require: false
  gem "guard-rubocop", require: false
  gem "haml_lint", require: false
  gem "listen"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "spring"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen"
  gem "web-console"
end

group :test do
  gem "capybara", require: false
  gem "capybara-screenshot", require: false
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "webdrivers"
  gem "webmock", require: false
end
