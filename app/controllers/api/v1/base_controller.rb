module Api
  module V1
    # BaseController is the parent for every API controller.
    # It sits between ApplicationController (global concerns) and the resource
    # controllers (ConversationsController, MessagesController, etc.).
    #
    # What lives here:
    #   - authenticate_user! — every API action requires a valid JWT
    #   - shared helpers reused across multiple resource controllers
    #
    # Why a separate BaseController instead of putting this in ApplicationController?
    #   ApplicationController is also the parent for Devise controllers (sessions,
    #   registrations). Those must NOT require a JWT — you can't log in if you're
    #   already required to be logged in. Splitting keeps auth-required vs public
    #   endpoints cleanly separated.
    class BaseController < ApplicationController
      # authenticate_user! is provided by Devise.
      # With devise-jwt it decodes the Bearer token from the Authorization header,
      # verifies signature + expiry + denylist, and sets current_user.
      # If anything fails → 401 Unauthorized (Devise handles the response).
      before_action :authenticate_user!
      # Q: How and where the expiry + denylist are being checked here in this layer?
      # A: authenticate_user! triggers the devise-jwt Warden strategy, which runs this chain:
      #      1. Extracts the raw token from the Authorization: Bearer <token> header
      #      2. JWT.decode — verifies the HS256 signature using secret_key_base
      #                     and checks the exp claim → raises JWT::ExpiredSignature if past
      #      3. JwtDenylist.jwt_revoked?(payload, user) — does Redis.exists?("jwt_denylist:<jti>")
      #                     → true if the token was logged out → treated as invalid
      #      4. User.find(payload["sub"]) — loads current_user from the DB
      #    All of this happens inside the devise-jwt gem (lib/devise/jwt/strategy.rb),
      #    invisible to our code. If any step fails, Warden calls authenticate_user!
      #    which renders 401 before our controller action ever runs.
    end
  end
end
