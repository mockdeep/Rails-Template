# frozen_string_literal: true

module Views
  module Accounts
    class Remove < Views::Base
      attr_accessor :user

      def initialize(user:)
        super()
        self.user = user
      end

      def view_template
        h1 { "Delete Account" }

        p do
          plain("This will permanently delete the account for ")
          strong { user.email }
          plain(". This cannot be undone.")
        end

        div(class: "actions") do
          button_to("Permanently Delete Account", account_path, method: :delete)
          a(href: account_path) { "Cancel" }
        end
      end
    end
  end
end
