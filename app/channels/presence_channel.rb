class PresenceChannel < ApplicationCable::Channel
  # PresenceChannel tracks which users are online and broadcasts status changes.
  #
  # How presence works at scale:
  #   - On subscribe: set a Redis key "presence:<user_id>" with a TTL of 35 seconds.
  #     The frontend pings every 30s to renew the TTL. If the TTL expires
  #     (browser crash, network drop), Redis auto-deletes the key → user is offline.
  #   - On unsubscribe: delete the key immediately → instant offline detection.
  #   - last_seen_at in PostgreSQL is updated on subscribe for persistent history
  #     (e.g. "last seen 2 hours ago"). Redis is the fast path for real-time status.
  #
  # Why Redis TTL instead of a DB flag?
  #   A "is_online" boolean in PostgreSQL would require an UPDATE on every ping
  #   and a background job to expire stale sessions. Redis TTL handles both for free.

  # ─── Subscribed ─────────────────────────────────────────────────────────────
  def subscribed
    stream_from "presence"
    set_online
    broadcast_status("online")
    # Send the current online roster directly to THIS new subscriber only.
    # Without this, the frontend presence store starts empty and every user
    # appears offline until their next 30s ping arrives. transmit() sends only
    # to the current connection — not a broadcast.
    transmit_initial_roster
  end
  # ─── Unsubscribed ───────────────────────────────────────────────────────────
  def unsubscribed
    set_offline
    broadcast_status("offline")
    stop_all_streams
  end
  # ─── ping ───────────────────────────────────────────────────────────────────
  # Client calls this every 30s to renew the Redis TTL and stay "online".
  # Without this, users would go offline after 35s even if still active.
  def ping
    set_online
  end

  private

  # Redis key: "presence:<user_id>", TTL: 35s (5s grace over the 30s ping interval)
  def set_online
    redis.setex("presence:#{current_user.id}", 35, "1")
    current_user.update_columns(last_seen_at: Time.current)
  end
  def set_offline
    redis.del("presence:#{current_user.id}")
  end
  # Broadcasts to ALL connected clients — everyone sees who went online/offline.
  # ActionCable.server.broadcast is the class-level broadcast (not instance).
  def broadcast_status(status)
    ActionCable.server.broadcast("presence", {
      user_id: current_user.id,
      username: current_user.username,
      status: status
    })
  end
  # Reuses the same Redis connection as JwtDenylist (/3).
  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/3"))
  end

  # Scan Redis for all presence:* keys and transmit the user IDs to the new
  # subscriber so their store is populated immediately on page load.
  # Uses SCAN (O(N) cursor-based) rather than KEYS (O(N) blocking) — safe in prod.
  def transmit_initial_roster
    online_user_ids = []
    redis.scan_each(match: "presence:*") do |key|
      # key format: "presence:<user_id>"
      user_id = key.split(":").last.to_i
      online_user_ids << user_id
    end
    transmit({ type: "initial_presence", online_user_ids: online_user_ids })
  end
end
