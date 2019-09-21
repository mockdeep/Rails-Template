# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  user_params = {
    email: "demo@exampoo.com",
    password: "super-secure",
    password_confirmation: "super-secure",
  }

  valid_create_params = { session: user_params.slice(:email, :password) }

  invalid_create_params = { session: {
    email: "wrong@email",
    password: "wrong password",
  } }

  describe "#new" do
    it "renders a new form" do
      get(:new)

      expect(response.body).to include("Log in to")
    end
  end

  describe "#create" do
    context "when user authenticates" do
      it "sets the user id in the session" do
        user = User.create!(user_params)

        post(:create, params: valid_create_params)

        expect(session[:user_id]).to eq(user.id)
      end

      it "redirects to the home page" do
        User.create!(user_params)

        post(:create, params: valid_create_params)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when user does not authenticate" do
      it "flashes an error" do
        User.create!(user_params)

        post(:create, params: invalid_create_params)

        expect(response.body).to include("Invalid email or password")
      end

      it "renders the new template" do
        User.create!(user_params)

        post(:create, params: invalid_create_params)

        expect(response.body).to include("Log in to")
      end
    end
  end

  describe "#destroy" do
    context "when user is not logged in" do
      it "redirects to log in page" do
        delete(:destroy)

        expect(response).to redirect_to(new_session_path)
      end

      it "does not clear the session" do
        session[:blah] = "boo"

        delete(:destroy)

        expect(session[:blah]).to eq("boo")
      end
    end

    it "signs out the user" do
      session[:user_id] = User.create!(user_params).id

      delete(:destroy)

      expect(session[:user_id]).to be(nil)
    end

    it "clears the session" do
      session[:user_id] = User.create!(user_params).id
      session[:blah] = "boo"

      delete(:destroy)

      expect(session[:blah]).to be(nil)
    end

    it "redirects to the home page" do
      user = User.create!(user_params)
      session[:user_id] = user.id

      delete(:destroy)

      expect(response).to redirect_to(root_path)
    end
  end
end
