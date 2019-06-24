# frozen_string_literal: true

require "action_mailer"

class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
