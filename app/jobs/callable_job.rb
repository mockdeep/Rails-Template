# frozen_string_literal: true

require_relative "application_job"

class CallableJob < ApplicationJob
  def perform(callable_name, *args, **kwargs)
    callable_name.constantize.call(*args, **kwargs)
  end
end
