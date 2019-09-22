# frozen_string_literal: true

Rails.application.routes.draw do
  require "sidekiq/web"

  mount Sidekiq::Web, at: "/sidekiq", constraints: AdminConstraint.new

  root to: "welcome#index"

  resource :account, only: [:new, :create, :show, :update, :destroy]
  resource :session, only: [:new, :create, :destroy]
end
