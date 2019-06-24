# frozen_string_literal: true

rails_require "app/models/application_record"

RSpec.describe ApplicationRecord do
  it "exists" do
    expect(described_class).to be_present
  end
end
