# frozen_string_literal: true

rails_require "app/jobs/callable_job"

RSpec.describe CallableJob do
  describe "#perform" do
    it "constantizes and calls the given job class with 0 args" do
      counts = {}
      stub_const("MyTestCallable", -> { counts[:yep] = "five" })

      described_class.new.perform("MyTestCallable")

      expect(counts).to eq(yep: "five")
    end

    it "constantizes and calls the given job class with several args" do
      counts = {}
      stub_const("MyTestCallable", ->(key, value) { counts[key] = value })

      described_class.new.perform("MyTestCallable", :foo, 5)

      expect(counts).to eq(foo: 5)
    end

    it "constantizes and calls the given job class with hash args" do
      counts = {}
      stub_const("MyTestCallable", ->(key:, value:) { counts[key] = value })

      described_class.new.perform("MyTestCallable", key: :foo, value: 5)

      expect(counts).to eq(foo: 5)
    end

    it "raises an error when constant does not exist" do
      expect { described_class.new.perform("NotACallable") }
        .to raise_error(NameError)
    end
  end
end
