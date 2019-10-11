# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LetMeKnowWhen
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(6.0)

    config.active_job.queue_adapter     = :sidekiq
    config.active_job.queue_name_prefix = "letmeknowwhen_#{Rails.env}"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.active_record.belongs_to_required_by_default = false
    config.action_view.form_with_generates_remote_forms = false

    config.autoload_paths << Rails.root.join("app/models/nulls")
    config.autoload_paths << Rails.root.join("lib/route_constraints")
  end
end
