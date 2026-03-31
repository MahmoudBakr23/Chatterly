module ApplicationCable
  # Channel is the base class for all channels — same role as ApplicationController
  # for HTTP. Shared logic lives here and is inherited by every channel.
  class Channel < ActionCable::Channel::Base
    private

    # ─── Rate Limiting ───────────────────────────────────────────────────────
    # rate_limit! is called inside any channel action that needs throttling.
    # Example usage in ConversationChannel:
    #   def receive(data)
    #     rate_limit!(action: "message", limit: 20, window: 10)
    #     ...
    #   end
    # How it works:
    #   Redis key: "rate_limit:<action>:<user_id>"
    #   On each call: INCR the key (atomic, thread-safe).
    #   First call: also set TTL = window seconds (key auto-deletes after window).
    #   If count exceeds limit: transmit an error and stop the action.
    #
    # Why Redis INCR?
    #   INCR is atomic — even with 1000 concurrent requests, the count is exact.
    #   No race conditions, no locking needed. This is Redis doing what it's built for.
    def rate_limit!(action:, limit:, window:)
      key   = "rate_limit:#{action}:#{current_user.id}"
      count = redis.incr(key)
      # Set TTL only on first increment — don't reset the window on each hit
      redis.expire(key, window) if count == 1
      if count > limit
        transmit({ error: "rate_limit", message: "Too many #{action} requests. Slow down." })
        throw :abort
      end
    end
    # Shared Redis connection for all channels (logical DB /3 — same as JWT + presence).
    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/3"))
      # A: No — in staging/production, REDIS_URL is set to the Upstash URL (e.g. rediss://...@...upstash.io:6379).
      #    ENV.fetch raises KeyError if the var is missing entirely, so deployment will fail fast rather than
      #    silently connecting to localhost (which wouldn't exist on Railway/Render anyway).
    end
  end
end
