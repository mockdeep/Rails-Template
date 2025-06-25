# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module YourAppNameHere
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(7.0)

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_record.belongs_to_required_by_default = false
    config.action_view.form_with_generates_remote_forms = false

    extra_paths = [
      Rails.root.join("app/models/nulls"),
      Rails.root.join("lib/route_constraints"),
    ]
    config.autoload_paths += extra_paths
    config.eager_load_paths += extra_paths
  end
end
