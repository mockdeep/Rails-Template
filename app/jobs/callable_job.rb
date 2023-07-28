# frozen_string_literal: true

require_relative "application_job"

class CallableJob < ApplicationJob
  def perform(callable_name, *, **)
    callable_name.constantize.call(*, **)
  end
end
