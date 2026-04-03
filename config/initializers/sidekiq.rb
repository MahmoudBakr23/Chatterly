# Sidekiq — background job processor
#
# Sidekiq runs as a separate process alongside Rails. It continuously polls
# Redis for jobs, pops them off the queue, and executes them.
#
# Why background jobs? Some work shouldn't block an HTTP response:
#   - Sending emails (slow, external service)
#   - Expiring missed calls after 30 seconds
#   - Cleaning up stale presence data
#   - Sending push notifications
#
# Without Sidekiq: user waits for ALL of that before getting their 200 OK.
# With Sidekiq:    Rails enqueues the job (< 1ms Redis write), returns 200 OK,
#                  Sidekiq picks it up and does the work in the background.
#
# Sidekiq uses Redis logical database /1 (separate from Action Cable on /0)
# to avoid key collisions — both use Redis but for completely different purposes.

redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
  # Sidekiq gets its own Redis connection pool — separate from Action Cable.
  # size: how many Redis connections Sidekiq maintains.
  # Rule: Sidekiq concurrency (threads) + 2 for overhead.
  size: (ENV.fetch("SIDEKIQ_CONCURRENCY", 5).to_i + 2)
}

Sidekiq.configure_server do |config|
  # configure_server runs inside the Sidekiq process (the worker)
  config.redis = redis_config

  # Concurrency: how many threads Sidekiq uses to process jobs in parallel.
  # Each thread processes one job at a time.
  # More threads = more jobs processed simultaneously = more Redis + DB connections.
  # Free tier: keep at 5. Production: scale with available CPU/RAM.
  config.concurrency = ENV.fetch("SIDEKIQ_CONCURRENCY", 5).to_i

  # Scheduled jobs — registered once when the Sidekiq server boots.
  # Runs on the 25th of each month at 00:00 UTC, creating next month's
  # messages partition before the 1st rolls over.
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      "create_message_partition" => {
        "cron"  => "0 0 25 * *",
        "class" => "CreateMessagePartitionJob"
      }
    )
  end
end

Sidekiq.configure_client do |config|
  # configure_client runs inside the Rails process (when enqueuing jobs)
  config.redis = redis_config
end
