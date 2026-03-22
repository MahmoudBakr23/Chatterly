module Api
  module V1
    # Overrides Devise::SessionsController to return JSON instead of HTML.
    #
    # Flow (login):
    #   1. Client POSTs { user: { email:, password: } }
    #   2. Devise authenticates credentials
    #   3. devise-jwt generates a JWT and sets Authorization header automatically
    #   4. respond_with fires — we render the user JSON body
    #
    # Flow (logout):
    #   1. Client sends DELETE with Authorization: Bearer <token>
    #   2. Devise + devise-jwt adds the JWT jti to the Redis denylist
    #   3. respond_to_on_destroy fires — we confirm with a JSON message
    class SessionsController < Devise::SessionsController
      respond_to :json

      private

      # respond_with is called on successful login.
      # The JWT is already in the response header at this point — we only control the body.
      #
      # TODO: def respond_with(resource, _opts = {})
      #         render json: { user: UserBlueprint.render_as_hash(resource, view: :with_email) }
      #       end
      def respond_with(resource, _opts = {})
        render json: { user: UserBlueprint.render_as_hash(resource, view: :with_email) }
      end

      # respond_to_on_destroy is called after logout.
      # By this point the JWT is already in the Redis denylist — it can never be used again.
      #
      # TODO: def respond_to_on_destroy
      #         render json: { message: "Logged out successfully" }
      #       end
      def respond_to_on_destroy
        render json: { message: "Logged out successfully" }
      end
    end
  end
end
