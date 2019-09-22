# frozen_string_literal: true

class AdminConstraint
  def matches?(request)
    return true if Rails.env.development?

    User.find(request.session[:user_id]).admin?
  end
end
