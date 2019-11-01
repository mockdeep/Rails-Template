# frozen_string_literal: true

require_relative "config/application"

Rails.application.load_tasks

if Rails.env.development? || Rails.env.test?
  require "bundler/audit/task"
  Bundler::Audit::Task.new
end
