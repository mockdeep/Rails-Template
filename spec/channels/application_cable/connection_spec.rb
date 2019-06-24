# frozen_string_literal: true

rails_require "app/channels/application_cable/connection"

RSpec.describe ApplicationCable::Connection do
  it "exists" do
    expect(described_class).to be_present
  end
end
