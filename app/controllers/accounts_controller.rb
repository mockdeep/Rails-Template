# frozen_string_literal: true

require_relative "application_controller"

class AccountsController < ApplicationController
  before_action(:authenticate_user, only: [:show, :update, :destroy])

  def new
    render(locals: { user: User.new })
  end

  def create
    user = User.new(user_params)
    if user.save
      flash[:success] = "Account created successfully"
      session[:user_id] = user.id
      redirect_to(root_path)
    else
      flash.now[:error] = "There was a problem setting up your account"
      render(:new, locals: { user: user })
    end
  end

  def show
    render(locals: { user: current_user })
  end

  def update
    if current_user.update(user_params)
      flash[:success] = "Account updated successfully"
      redirect_to(root_path)
    else
      flash.now[:error] = "There was a problem updating your account"
      render(:show, locals: { user: current_user })
    end
  end

  def destroy
    if current_user.destroy
      session.clear
      flash[:success] = "Account permanently deleted"
      redirect_to(root_path)
    else
      flash.now[:error] = "Account could not be deleted"
      render(:show, locals: { user: current_user })
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
