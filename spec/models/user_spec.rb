# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to have_secure_password }

  it "allows good emails" do
    good_emails = [
      "b@b.com", "mrspicy+extra@yepyep.com", "you.are@atthe.museum"
    ]

    expect(described_class.new).to allow_values(*good_emails).for(:email)
  end

  it "does not allow bad emails" do
    bad_emails = [
      "b#b.com", "mrspicy>extra@yepyep.com", "blahbloo"
    ]

    expect(described_class.new).not_to allow_values(bad_emails).for(:email)
  end
end
