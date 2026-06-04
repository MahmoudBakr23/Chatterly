source "https://rubygems.org"

ruby "3.4.4"

# ─── Core ─────────────────────────────────────────────────────────────────────
gem "rails", "~> 8.1.2"
gem "pg", "~> 1.1"            # PostgreSQL adapter
gem "puma", ">= 5.0"          # Web server — handles HTTP + WebSocket connections

# ─── Caching (Rails.cache) ────────────────────────────────────────────────────
# Solid Cache is disabled until a dedicated cache DB is provisioned.
# Using :memory_store in production.rb for now.
# To re-enable: uncomment this gem + the cache: block in database.yml,
# then run db:prepare to create the Solid Cache tables.
# gem "solid_cache"

# ─── Background Jobs ──────────────────────────────────────────────────────────
# Sidekiq: Redis-backed job queue. Industry standard for high-throughput Rails apps.
# Handles things like sending emails, cleaning up expired tokens, expiring missed calls.
# Alternative was Solid Queue (PostgreSQL-backed) but it doesn't match Sidekiq's
# throughput at scale — Sidekiq can process millions of jobs/day on a single worker.
gem "sidekiq", "~> 8.1"
gem "sidekiq-cron", "~> 2.0"  # Recurring scheduled jobs on top of Sidekiq

# ─── Real-time / WebSockets ───────────────────────────────────────────────────
# Action Cable is built into Rails — no gem needed.
# But its pub/sub ADAPTER needs to be Redis at scale.
# Solid Cable (PostgreSQL polling) tops out at a few thousand concurrent connections.
# Redis pub/sub is O(1) for fan-out regardless of subscriber count.
# We configure this in config/cable.yml — the gem just provides the Redis client.
gem "redis", "~> 5.0"

# ─── Auth ─────────────────────────────────────────────────────────────────────
gem "devise", "~> 5.0"        # Full auth: registration, login, bcrypt password hashing
gem "devise-jwt", "~> 0.12"   # JWT token strategy on top of Devise (stateless API auth)

# ─── API ──────────────────────────────────────────────────────────────────────
gem "rack-cors"                # Allow cross-origin requests from Next.js (port 3000)
gem "blueprinter"              # Serializes ActiveRecord models to clean, controlled JSON

# ─── Authorization ────────────────────────────────────────────────────────────
gem "pundit", "~> 2.4"         # Policy-based authorization — one class per model

# ─── Performance ──────────────────────────────────────────────────────────────
gem "bootsnap", require: false  # Speeds up Rails boot via caching

# ─── Deployment ───────────────────────────────────────────────────────────────
gem "kamal", require: false     # Docker-based deployment
gem "thruster", require: false  # HTTP caching + compression layer for Puma

# ─── Windows compatibility ────────────────────────────────────────────────────
gem "tzinfo-data", platforms: %i[ windows jruby ]

# ─── Development & Test ───────────────────────────────────────────────────────
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "dotenv-rails"                           # Loads .env into ENV in development
  gem "brakeman", require: false               # Security vulnerability scanner
  gem "bundler-audit", require: false          # Checks gems for known CVEs
  gem "rubocop-rails-omakase", require: false  # Code style enforcement
end

group :development do
  gem "annotate"  # Adds DB schema as comments at the top of model files
end
