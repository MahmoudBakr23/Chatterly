# Chatterly API

Rails 8 JSON API backend for [Chatterly](https://github.com/MahmoudBakr23/chatterly-client) — a real-time chat app with voice/video calling. Built for scale: REST + WebSocket hybrid, PostgreSQL with native time-based partitioning, Redis pub/sub for Action Cable, and stateless JWT auth with a Redis denylist.

## Stack

| Layer | Technology |
|---|---|
| Runtime | Ruby 3.4.4 |
| Framework | Rails 8.1.2 (API mode) |
| Database | PostgreSQL 17 (partitioned `messages` table) |
| Pub/Sub + Cache | Redis (logical DBs: `/0` Action Cable, `/1` Sidekiq, `/2` cache, `/3` JWT + presence) |
| Background Jobs | Sidekiq 7 |
| Auth | Devise 5 + devise-jwt (JWT in `Authorization` header, denylist in Redis) |
| Authorization | Pundit 2 (one policy per resource) |
| Serialization | Blueprinter (reused across HTTP responses and WebSocket broadcasts) |
| Web Server | Puma 7 (cluster mode, `preload_app!`) |

## Architecture

```
Next.js Client
  │
  ├── HTTP (REST)       → Puma → Rails Controllers → Pundit Policies → Blueprinter
  │                                                          ↓
  │                                                    PostgreSQL 17
  │                                                 (partitioned messages)
  │
  └── WebSocket         → Action Cable → Redis pub/sub → broadcast to subscribers
       ?token=<JWT>          connection.rb authenticates via JWT
```

**Key architectural decisions:**
- **Redis denylist** for JWT logout — O(1) TTL lookup, no DB read on every request
- **PostgreSQL native partitioning** on `messages.created_at` (monthly) — handles hundreds of millions of rows without sharding
- **Blueprinter over JBuilder** — same serializer instance reused in HTTP responses and Action Cable broadcasts
- **Redis adapter for Action Cable** — O(1) pub/sub fan-out; Solid Cable (PostgreSQL polling) caps out at ~10k concurrent connections
- **Pundit policies** — all authorization logic centralized, never in controllers or models

## API Reference

All `/api/v1` endpoints require `Authorization: Bearer <token>`.

### Auth

| Method | Path | Description |
|---|---|---|
| `POST` | `/auth/register` | Create account, returns JWT |
| `POST` | `/auth/login` | Login, returns JWT |
| `DELETE` | `/auth/logout` | Logout, adds JWT to Redis denylist |

### Users

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/v1/users` | Search users (`?search=alice`) |
| `GET` | `/api/v1/users/me` | Current user's full profile (includes email) |
| `GET` | `/api/v1/users/:id` | Public profile |
| `PATCH` | `/api/v1/users/:id` | Update own profile |

### Conversations

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/v1/conversations` | List joined conversations |
| `POST` | `/api/v1/conversations` | Create DM or group |
| `GET` | `/api/v1/conversations/:id` | Show conversation |
| `DELETE` | `/api/v1/conversations/:id` | Delete (admin only) |
| `POST` | `/api/v1/conversations/:id/memberships` | Add member |
| `DELETE` | `/api/v1/conversations/:id/memberships/:id` | Remove member |

### Messages

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/v1/conversations/:id/messages` | Paginated history (cursor-based) |
| `POST` | `/api/v1/conversations/:id/messages` | Send message |
| `PATCH` | `/api/v1/conversations/:id/messages/:id` | Edit own message |
| `DELETE` | `/api/v1/conversations/:id/messages/:id` | Soft-delete (own or admin) |

### Calls

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/conversations/:id/calls` | Initiate call |
| `GET` | `/api/v1/conversations/:id/calls/active` | Get active call (late join) |
| `PUT` | `/api/v1/conversations/:id/calls/:id/accept` | Accept incoming call |
| `PUT` | `/api/v1/conversations/:id/calls/:id/decline` | Decline call |
| `DELETE` | `/api/v1/conversations/:id/calls/:id` | End call |

### Reactions

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/reactions` | Add reaction (`{ message_id, emoji }`) |
| `DELETE` | `/api/v1/reactions/:id` | Remove reaction |

### WebSocket Channels

Connect at `ws://localhost:3001/cable?token=<JWT>`.

| Channel | Purpose |
|---|---|
| `ConversationChannel` | Real-time messages, edits, deletes, reactions |
| `PresenceChannel` | Online/offline status with Redis TTL auto-expiry |
| `CallChannel` | WebRTC signaling (offer/answer/ICE), call lifecycle events |
| `UserChannel` | Personal stream for incoming call notifications |

## Local Setup

**Prerequisites:** Ruby 3.4.4, PostgreSQL 17, Redis

```bash
git clone https://github.com/MahmoudBakr23/Chatterly.git chatterly-api
cd chatterly-api
bundle install

# Environment
cp .env.example .env
# Edit .env — see Environment Variables section below

# Database
bin/rails db:create db:migrate

# Redis (separate terminal)
redis-server

# Sidekiq (separate terminal)
bundle exec sidekiq

# Rails on port 3001
WEB_CONCURRENCY=0 bin/rails server -p 3001
```

> **macOS note:** `WEB_CONCURRENCY=0` disables Puma cluster mode locally to avoid a fork-safety crash (`NSCharacterSet` + `preload_app!`). On staging/production, set `WEB_CONCURRENCY` to the number of CPU cores.

## Environment Variables

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string (Supabase in production) |
| `DATABASE_REPLICA_URL` | Optional read replica — zero code change to enable |
| `REDIS_URL` | Redis base URL (logical DBs appended per service) |
| `DEVISE_JWT_SECRET_KEY` | Secret for signing JWTs |
| `FRONTEND_URL` | Allowed CORS origin (e.g. `http://localhost:3000`) |
| `WEB_CONCURRENCY` | Puma worker count (`0` for local dev) |
| `RAILS_MASTER_KEY` | Decrypts `credentials.yml.enc` |

## Project Structure

```
app/
  channels/          # Action Cable — connection auth + 4 channels
  controllers/
    api/v1/          # Versioned REST controllers (thin — orchestration only)
  blueprints/        # Blueprinter serializers (shared by HTTP + WebSocket)
  models/            # User, Conversation, Message, Reaction, CallSession, CallParticipant
  policies/          # Pundit — one policy file per model
  services/          # Business logic service objects
  jobs/              # Sidekiq jobs (e.g. MissedCallJob — fires after 30s unanswered)
config/
  routes.rb          # All routes with inline documentation
  cable.yml          # Redis adapter for production, async for dev
  database.yml       # Pool formula, PgBouncer compat, read replica slot
  puma.rb            # Worker/thread config
```

## Data Model

- **`messages`** — partitioned by `created_at` (monthly); composite PK `(id, created_at)`; soft deletes via `deleted_at`
- **`call_sessions`** — 6-state lifecycle: `calling → ringing → active → ended / declined / missed`
- **`conversation_members`** — composite unique index on `(conversation_id, user_id)`; leftmost prefix covers conversation-only queries
- **`reactions`** — stores `message_created_at` alongside `message_id` for partition-aware lookups

## Deployment

Deployed via [Kamal](https://kamal-deploy.org/) (Docker-based):

```bash
kamal deploy          # deploy
kamal app logs        # tail logs
kamal app exec --interactive --reuse "bin/rails console"  # Rails console
```

## Quality Gates

Run before every push:

```bash
bundle exec rubocop -A     # lint + autofix
bundle exec brakeman -q    # security scan
bundle exec bundler-audit  # check gems for CVEs
```
