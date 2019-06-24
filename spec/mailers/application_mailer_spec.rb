# frozen_string_literal: true

rails_require "app/mailers/application_mailer"

RSpec.describe ApplicationMailer do
  it "exists" do
    expect(described_class).to be_present
  end
end
