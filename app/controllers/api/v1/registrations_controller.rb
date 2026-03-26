module Api
  module V1
    # Overrides Devise::RegistrationsController to return JSON instead of HTML.
    # Devise already handles: password hashing, uniqueness validation, saving the user.
    # We only need to control what JSON gets sent back.
    #
    # Flow:
    #   1. Client POSTs { user: { email:, username:, password:, display_name: } }
    #   2. Devise creates the user (or collects errors)
    #   3. devise-jwt generates a JWT and sets it in the Authorization response header
    #   4. respond_with fires — we render the JSON body
    #
    # Why respond_to :json?
    #   Tells Devise to call our respond_with for JSON requests.
    #   Without it Devise tries to render a view (which doesn't exist in API mode).
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      # Permit extra sign-up params that Devise doesn't know about by default.
      # Without this, username and display_name are stripped before the User is built,
      # causing blank username validation failures.
      before_action :configure_sign_up_params, only: [ :create ]

      private

      def configure_sign_up_params
        devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :display_name ])
      end

      # Called by Devise after create — resource is the new User.
      # resource.persisted? is true if save succeeded, false if validation failed.
      #
      # TODO: def respond_with(resource, _opts = {})
      #         if resource.persisted?
      #           render json: {
      #             message: "Registered successfully",
      #             user: UserBlueprint.render_as_hash(resource, view: :with_email)
      #           }, status: :created
      #         else
      #           render json: { errors: resource.errors.full_messages },
      #                  status: :unprocessable_entity
      #         end
      #       end
      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            message: "Registered successfully",
            user: UserBlueprint.render_as_hash(resource, view: :with_email)
          }, status: :created
        else
          render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
