# frozen_string_literal: true

require "rails_helper"

RSpec.describe "user sessions" do
  def user_params
    {
      email: "demo@lmkw.io",
      password: "secret",
      password_confirmation: "secret",
    }
  end

  def sign_in_with(email:, password:)
    visit("/")

    click_link("Log In")

    expect(page).to have_text("Log in to YourAppNameHere")

    fill_in("Email", with: email)
    fill_in("Password", with: password)

    click_button("Log In")
  end

  it "allows a user to log into their account" do
    user = User.create!(user_params)

    sign_in_with(email: user.email, password: user.password)

    expect(page).to have_text(user.email)
    expect(page).to have_link("Account")
    expect(page).to have_no_link("Log In")
  end

  it "does not allow a user to log in with an invalid email" do
    user = User.create!(user_params)

    sign_in_with(email: "wrong@email", password: user.password)

    expect(page).to have_flash(:error, "Invalid email or password")
    expect(page).to have_text("Log in to YourAppNameHere")
    expect(page).to have_no_text(user.email)
  end

  it "does not allow a user to log in with an invalid password" do
    user = User.create!(user_params)

    sign_in_with(email: user.email, password: "wrong password")

    expect(page).to have_flash(:error, "Invalid email or password")
    expect(page).to have_text("Log in to YourAppNameHere")
    expect(page).to have_no_text(user.email)
  end

  it "allows a user to log out" do
    user = User.create!(user_params)

    sign_in_with(email: user.email, password: user.password)

    click_link("Log Out")

    expect(page).to have_no_text(user.email)
    expect(page).to have_link("Log In")
  end
end
