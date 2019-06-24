# frozen_string_literal: true

rails_require "app/channels/application_cable/channel"

RSpec.describe ApplicationCable::Channel do
  it "exists" do
    expect(described_class).to be_present
  end
end
