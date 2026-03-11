# JwtDenylist — Redis-backed JWT revocation strategy for devise-jwt.
#
# When a user logs out, devise-jwt calls jwt_revoked? on every subsequent
# request and revoke! on logout. We implement both using Redis instead of
# a database table for two reasons:
#   1. Speed — every API request checks this. Redis GET is ~0.1ms vs ~5ms DB query.
#   2. Auto-expiry — Redis TTL deletes the key automatically when the JWT expires.
#      A DB table would accumulate rows forever without a cleanup job.
#
# This is NOT an ActiveRecord model — it has no table.
# It's a plain Ruby class that implements the devise-jwt revocation interface.
#
# Redis key format:  jwt_denylist:<jti>
# Redis value:       "1" (presence is all that matters)
# Redis TTL:         set to the token's remaining lifetime in seconds

class JwtDenylist
  # ─── Redis connection ────────────────────────────────────────────────────────
  # Uses logical database /3 (JWT denylist + presence) as configured in cable.yml
  # Separate from Action Cable (/0), Sidekiq (/1), and cache (/2).
  # TODO: def self.redis
  #         @redis ||= Redis.new(
  #           url: ENV.fetch("REDIS_URL", "redis://localhost:6379/3")
  #         )
  #       end

  # ─── devise-jwt interface ─────────────────────────────────────────────────
  # jwt_revoked? is called on EVERY authenticated request.
  # payload contains: { "sub" => user_id, "jti" => unique_token_id, "exp" => expiry }
  # jti = JWT ID — a unique identifier for this specific token instance.
  # TODO: def self.jwt_revoked?(payload, _user)
  #         redis.exists?("jwt_denylist:#{payload['jti']}")
  #       end

  # revoke_jwt is called once on logout.
  # We store the jti with a TTL equal to the token's remaining lifetime.
  # After the token would have expired anyway, the key auto-deletes.
  # TODO: def self.revoke_jwt(payload, _user)
  #         jti = payload["jti"]
  #         # remaining_ttl: seconds until the token expires naturally
  #         # We never store a key longer than the token's own lifetime
  #         expiry = payload["exp"]
  #         remaining_ttl = expiry - Time.now.to_i
  #         redis.setex("jwt_denylist:#{jti}", remaining_ttl, "1") if remaining_ttl.positive?
  #       end
end
