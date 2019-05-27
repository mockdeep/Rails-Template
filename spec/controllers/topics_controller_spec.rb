# frozen_string_literal: true

require "rails_helper"

RSpec.describe(TopicsController) do
  render_views

  describe "#index" do
    it "renders a page" do
      title = Faker::Lorem.sentence
      Topic.create!(title: title)
      get(:index)
      expect(response.body).to(include(title))
    end
  end
end
