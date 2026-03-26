module ApplicationCable
  # Connection is the WebSocket handshake layer — it runs ONCE when a client connects.
  # Think of it as the equivalent of ApplicationController for HTTP requests, but for WS.
  # Its only job: authenticate the user and reject unauthorized connections early.
  #
  # How JWT gets here:
  #   The frontend passes the token in the WebSocket URL query string:
  #   ws://localhost:3001/cable?token=<jwt>
  #   We read it from request.params["token"].
  #
  # identified_by :current_user
  #   This sets current_user as the connection identifier — available in ALL channels
  #   as `current_user`. Also used by Action Cable to clean up subscriptions when
  #   the user disconnects (it calls reject! or close on all their channels).
  class Connection < ActionCable::Connection::Base
    # identified_by :current_user tells Action Cable to use current_user as the
    # unique identifier for this connection. Every channel can access current_user.
    # TODO: identified_by :current_user
    identified_by :current_user
    # called is the entry point — runs during the WebSocket handshake.
    # If find_verified_user raises reject_unauthorized_connection, the WS is closed.
    # TODO: def connect
    #         self.current_user = find_verified_user
    #       end
    def connect
      self.current_user = find_verified_user
    end

    private

    # find_verified_user decodes the JWT from the query string and finds the user.
    # We decode manually here — devise-jwt only handles HTTP requests automatically.
    # reject_unauthorized_connection closes the WebSocket with a 401-equivalent.
    # TODO: def find_verified_user
    #         token = request.params["token"]
    #         return reject_unauthorized_connection if token.blank?
    #
    #         # JWT.decode returns [payload, header]. We only need the payload.
    #         payload = JWT.decode(
    #           token,
    #           Rails.application.credentials.secret_key_base,
    #           true,
    #           algorithms: ["HS256"]
    #         ).first
    #
    #         user = User.find_by(id: payload["sub"])
    #         user || reject_unauthorized_connection
    #       rescue JWT::DecodeError
    #         reject_unauthorized_connection
    #       end
    def find_verified_user
      token = request.params["token"]
      return reject_unauthorized_connection if token.blank?

      # JWT.decode returns [payload, header]. We only need the payload.
      payload = JWT.decode(
        token,
        Rails.application.credentials.secret_key_base,
        true,
        algorithms: [ "HS256" ]
      ).first

      user = User.find_by(id: payload["sub"])
      # Reject if user not found OR token was revoked (logged out) — single guard.
      return reject_unauthorized_connection if user.nil? || JwtDenylist.jwt_revoked?(payload, user)

      user
    rescue JWT::DecodeError
      reject_unauthorized_connection
    end
  end
end
