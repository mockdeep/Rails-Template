# frozen_string_literal: true

require "factory_bot_rails"

module FactoryCache
  extend self

  def user
    @user ||= FactoryBot.create(:user)
  end

  def reset
    @user = nil
  end
end

RSpec.configure do |config|
  config.include(FactoryBot::Syntax::Methods)

  config.after do
    FactoryBot.rewind_sequences
    FactoryCache.reset
  end
end

module FactoryBot
  module Syntax
    module Methods
      def default_user
        FactoryCache.user
      end
    end
  end
end
