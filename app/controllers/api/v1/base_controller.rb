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
    end
  end
end
