# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountsController do
  def valid_create_params
    {
      user: {
        email: "demo@exampoo.com",
        password: "super-secure",
        password_confirmation: "super-secure",
      },
    }
  end

  def invalid_create_params
    {
      user: {
        email: "demo#exampoo.com",
        password: "super-secure",
        password_confirmation: "not-super-insecure",
      },
    }
  end

  describe "#new" do
    it "renders a new form" do
      get(:new)

      expect(response.body).to include("New Account")
    end
  end

  describe "#create" do
    context "when the user successfully saves" do
      it "flashes a success message" do
        post(:create, params: valid_create_params)

        expect(flash[:success]).to include("Account created")
      end

      it "sets the user_id in the session" do
        post(:create, params: valid_create_params)

        expect(session[:user_id]).to eq(User.last.id)
      end

      it "redirects to the root path" do
        post(:create, params: valid_create_params)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the user does not successfully save" do
      it "flashes an error message" do
        post(:create, params: invalid_create_params)

        expect(response.body).to include("There was a problem")
      end

      it "renders the new page" do
        post(:create, params: invalid_create_params)

        expect(response.body).to include("New Account")
      end
    end
  end

  describe "#show" do
    it "redirects to log in page when user is not logged in" do
      get(:show)

      expect(response).to redirect_to(new_session_path)
    end

    it "renders the user account page" do
      user = User.create!(valid_create_params[:user])
      session[:user_id] = user.id

      get(:show)

      expect(response.body).to include("My Account")
    end
  end

  describe "#update" do
    def valid_update_params = { user: { email: "new@email.com" } }
    def invalid_update_params = { user: { email: "new#email.com" } }

    context "when the user is not logged in" do
      it "redirects to log in page" do
        put(:update, params: valid_update_params)

        expect(response).to redirect_to(new_session_path)
      end

      it "does not update the user" do
        user = User.create!(valid_create_params[:user])

        expect { put(:update, params: valid_update_params) }
          .to not_change_record(user, :email).from("demo@exampoo.com")
      end
    end

    context "when the user successfully updates" do
      it "updates the user" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        expect { put(:update, params: valid_update_params) }
          .to change_record(user, :email)
          .from("demo@exampoo.com").to("new@email.com")
      end

      it "flashes a success message" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        put(:update, params: valid_update_params)

        expect(flash[:success]).to include("updated successfully")
      end

      it "redirects to the root path" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        put(:update, params: valid_update_params)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the user does not successfully update" do
      it "does not update the user" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        expect { put(:update, params: invalid_update_params) }
          .not_to change_record(user, :email).from("demo@exampoo.com")
      end

      it "flashes an error message" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        put(:update, params: invalid_update_params)

        expect(flash.now[:error]).to include("problem updating your account")
      end

      it "renders the show template" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        put(:update, params: invalid_update_params)

        expect(response.body).to include("My Account")
      end
    end
  end

  describe "#destroy" do
    context "when user is not logged in" do
      it "redirects to log in page" do
        delete(:destroy)

        expect(response).to redirect_to(new_session_path)
      end

      it "does not destroy the user" do
        user = User.create!(valid_create_params[:user])

        expect { delete(:destroy) }.to not_delete_record(user)
      end
    end

    context "when the user is successfully destroyed" do
      it "clears the session" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        delete(:destroy)

        expect(session[:user_id]).to be_nil
      end

      it "flashes a success message" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        delete(:destroy)

        expect(flash[:success]).to include("Account permanently deleted")
      end

      it "redirects to the root path" do
        user = User.create!(valid_create_params[:user])
        session[:user_id] = user.id

        delete(:destroy)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the user is not successfully destroyed" do
      it "flashes an error message" do
        fake_user = record_double(User, destroy: false)

        session[:user_id] = fake_user.id

        delete(:destroy)

        expect(flash.now[:error]).to include("Account could not be deleted")
      end

      it "renders the show template" do
        fake_user = record_double(User, destroy: false)

        session[:user_id] = fake_user.id

        delete(:destroy)

        expect(response.body).to include("My Account")
      end
    end
  end
end
