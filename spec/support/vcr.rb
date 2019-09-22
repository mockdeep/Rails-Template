# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.hook_into(:webmock)
  config.configure_rspec_metadata!
  config.cassette_library_dir = "spec/support/vcr_cassettes"
  config.default_cassette_options = {
    allow_unused_http_interactions: false,
    decode_compressed_response: true,
    record: ENV["CI"] ? :none : :once,
    update_content_length_header: true,
  }
  config.ignore_hosts("chromedriver.storage.googleapis.com")
  # config.ignore_localhost = true

  config.before_record do |interaction|
    # make response body plain text rather than binary format
    interaction.response.body.force_encoding("UTF-8")
  end
end
