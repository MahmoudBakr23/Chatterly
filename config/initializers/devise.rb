# Devise initializer — authentication configuration for Chatterly
#
# Devise is a full authentication solution for Rails. It handles:
#   - Password hashing (bcrypt — one-way hash, never stored in plaintext)
#   - Registration, login, logout flows
#   - Validations (email format, password length, uniqueness)
#   - Token lifecycle via devise-jwt
#
# devise-jwt extends Devise with a JWT (JSON Web Token) strategy.
# Instead of cookies/sessions (which don't work cleanly cross-origin),
# JWTs travel in the Authorization header — stateless, cross-origin safe.

Devise.setup do |config|
  # ─── Mailer ─────────────────────────────────────────────────────────────────
  # Used for password reset emails. Not critical for now but required by Devise.
  config.mailer_sender = ENV.fetch("MAILER_FROM", "no-reply@chatterly.app")

  # ─── ORM ────────────────────────────────────────────────────────────────────
  # Tell Devise we're using ActiveRecord (PostgreSQL), not Mongoid (MongoDB).
  require "devise/orm/active_record"

  # ─── Auth key ───────────────────────────────────────────────────────────────
  # The field Devise uses to find the user on login. Email is the default.
  config.authentication_keys = [ :email ]

  # ─── Password ───────────────────────────────────────────────────────────────
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ─── Timeouts ───────────────────────────────────────────────────────────────
  # How long a remember-me token lasts (we use JWT expiry instead, but required)
  config.remember_for = 2.weeks

  # Lock account after failed attempts — brute force protection
  config.lock_strategy = :failed_attempts
  config.maximum_attempts = 10
  config.unlock_strategy = :time
  config.unlock_in = 1.hour

  # ─── JWT Configuration ──────────────────────────────────────────────────────
  # devise-jwt plugs into Devise's Warden strategy layer.
  # On login:    Devise authenticates → devise-jwt generates JWT → returned in Authorization header
  # On request:  devise-jwt reads Authorization header → decodes JWT → sets current_user
  # On logout:   devise-jwt revokes the token (JTI stored in Redis with TTL)
  #
  # JWT anatomy: header.payload.signature
  #   header:    { alg: "HS256", typ: "JWT" }
  #   payload:   { sub: user_id, jti: unique_token_id, exp: expiry_timestamp }
  #   signature: HMAC-SHA256(header + payload, secret_key_base) — tamper-proof
  #
  # The signature is what makes JWTs trustworthy — only your server knows the
  # secret_key_base, so only your server can produce a valid signature.
  # Rails.application.credentials.secret_key_base is a 128-char random string
  # generated on `rails new` — never share it, never commit it.

  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.secret_key_base

    # dispatch_requests: which endpoints trigger JWT generation (login)
    # After successful POST to /api/v1/auth/login, devise-jwt generates
    # a token and adds it to the Authorization response header.
    jwt.dispatch_requests = [
      [ "POST", %r{^/api/v1/auth/login$} ]
    ]

    # revocation_requests: which endpoints trigger JWT revocation (logout)
    # After DELETE to /api/v1/auth/logout, the token's JTI is stored in Redis
    # with a TTL matching the token's remaining lifetime — auto-expires.
    jwt.revocation_requests = [
      [ "DELETE", %r{^/api/v1/auth/logout$} ]
    ]

    # Token lifetime — 24 hours balances UX and security.
    # Too short → users get logged out constantly
    # Too long  → stolen tokens stay valid longer
    jwt.expiration_time = 24.hours.to_i
  end

  # ─── Navigation formats ─────────────────────────────────────────────────────
  # Tell Devise this is an API — don't redirect on auth failure, return JSON.
  config.navigational_formats = []

  # ─── Sign out via ───────────────────────────────────────────────────────────
  # Use DELETE for logout (RESTful) — matches revocation_requests path above.
  config.sign_out_via = :delete
end
