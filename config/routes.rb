# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "welcome#index"

  resource :account, only: [:new, :create, :show, :update, :destroy]
  resource :session, only: [:new, :create, :destroy]

  constraints AdminConstraint.new do
    mount GoodJob::Engine, at: "good_job"
  end
end
