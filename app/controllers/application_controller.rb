# frozen_string_literal: true

require "action_controller"

class ApplicationController < ActionController::Base
  before_action(:authenticate_user)

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session.key?(:user_id)
  end
  helper_method :current_user

  def authenticate_user
    redirect_to(root_path) unless current_user
  end
end
