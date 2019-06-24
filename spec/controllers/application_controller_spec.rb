# frozen_string_literal: true

rails_require "app/controllers/application_controller"

RSpec.describe ApplicationController do
  it "exists" do
    expect(described_class).to be_present
  end
end
