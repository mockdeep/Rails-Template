# frozen_string_literal: true

rails_require "app/jobs/application_job"

RSpec.describe ApplicationJob do
  it "exists" do
    expect(described_class).to be_present
  end
end
