# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.3"

gem "rails", "~> 5.2.3"

gem "bcrypt"
gem "bootsnap", require: false
gem "pg"
gem "puma"
gem "sass-rails"
gem "turbolinks"
gem "uglifier"

group :development, :test do
  gem "byebug"
  gem "faker"
  gem "guard", require: false
  gem "guard-rspec", require: false
  gem "rspec-rails"
end

group :development do
  gem "brakeman", require: false
  gem "listen"
  gem "rubocop"
  gem "rubocop-rspec"
  gem "spring"
  gem "spring-watcher-listen"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "webdrivers"
end
