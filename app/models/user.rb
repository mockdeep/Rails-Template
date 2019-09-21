# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP

  def self.find_by(args)
    super || NullUser.new
  end

  def self.find(id)
    id ? super : NullUser.new
  end

  def logged_in?
    true
  end
end
