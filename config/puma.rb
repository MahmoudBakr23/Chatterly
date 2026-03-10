# Puma is our web server. It handles two things simultaneously:
#   1. HTTP requests (REST API calls from Next.js)
#   2. WebSocket connections (Action Cable — real-time messages, presence, calls)
#
# Puma has two concurrency levers: WORKERS and THREADS.
# Understanding both is key to horizontal vs vertical scaling.
#
# ─── WORKERS (processes) ──────────────────────────────────────────────────────
# Each worker is a full copy of your Rails app running as a separate OS process.
# Workers bypass Ruby's GVL (Global VM Lock) — they run truly in parallel.
# GVL = Ruby's internal rule that only ONE thread per process executes Ruby code
# at a time. Workers get around this by being separate processes entirely.
#
# Rule of thumb: 1 worker per CPU core.
# On a 2-core free tier server → WEB_CONCURRENCY=2
# On a 16-core production server → WEB_CONCURRENCY=16
#
# This is VERTICAL scaling in action — using all cores on one machine.
# When you add more machines (HORIZONTAL scaling), each runs its own Puma
# with the same worker count, behind a load balancer.
#
# ─── THREADS (within each worker) ────────────────────────────────────────────
# Threads share memory inside one worker process.
# Ruby's GVL means only one thread runs Ruby code at a time per process —
# BUT threads DO run concurrently during I/O (DB queries, Redis, HTTP calls).
# Since Rails is mostly I/O, threads are effective even with the GVL.
#
# 3 threads is the sweet spot: enough concurrency without memory bloat.
#
# ─── THE CRITICAL FORMULA ─────────────────────────────────────────────────────
# Total DB connections per server = workers × threads
# Those connections must match your database.yml pool size AND
# fit within PgBouncer's connection limit on the other side.
# Example: 2 workers × 3 threads = 6 DB connections per server
# With 3 servers behind a load balancer = 18 total DB connections
# PgBouncer collapses those 18 into ~5 real PostgreSQL connections.

workers_count = Integer(ENV.fetch("WEB_CONCURRENCY", 1))
threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 3))

workers workers_count
threads threads_count, threads_count

# Port 3001 — our Rails API lives here. Next.js lives on 3000.
port ENV.fetch("PORT", 3001)

# preload_app! loads the entire Rails app BEFORE forking workers.
# Benefit: Ruby uses copy-on-write memory — workers share the loaded app's
# memory pages until they write to them. On a 2-worker server this can
# save 100-200MB of RAM. Critical on free tier servers with 512MB.
# Trade-off: You must re-establish connections (DB, Redis) after fork — see below.
preload_app!

# After Puma forks a worker, connections opened before the fork are shared
# between processes — which causes corrupt data. We reconnect each worker
# to its own fresh connections to PostgreSQL and Redis after forking.
on_worker_boot do
  # Reconnect ActiveRecord (PostgreSQL) — each worker gets its own pool
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Allow `bin/rails restart` to work in development
plugin :tmp_restart

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
