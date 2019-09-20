# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
end
