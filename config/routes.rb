Rails.application.routes.draw do
  # ─── Auth ─────────────────────────────────────────────────────────────────
  # Devise maps:
  #   POST   /auth/register  → RegistrationsController#create
  #   POST   /auth/login     → SessionsController#create  (issues JWT in Authorization header)
  #   DELETE /auth/logout    → SessionsController#destroy (adds JWT to Redis denylist)
  # Custom controllers let us control the JSON response shape.
  devise_for :users,
    path: "auth",
    path_names: { sign_in: "login", sign_out: "logout", registration: "register" },
    controllers: { sessions: "api/v1/sessions", registrations: "api/v1/registrations" },
    defaults: { format: :json }

  # ─── API v1 ───────────────────────────────────────────────────────────────
  # All endpoints live under /api/v1 — versioning lets us ship /api/v2 later
  # without breaking existing frontend clients.
  namespace :api do
    namespace :v1 do
      # ── Users ──────────────────────────────────────────────────────────────
      # GET   /api/v1/users      → index  (search by ?search=alice)
      # GET   /api/v1/users/me   → me     (current user's own profile, with email)
      # GET   /api/v1/users/:id  → show   (public profile)
      # PATCH /api/v1/users/:id  → update (own profile only — enforced by Pundit)
      resources :users, only: [ :index, :show, :update ] do
        collection { get :me }
      end

      # ── Conversations ──────────────────────────────────────────────────────
      resources :conversations, only: [ :index, :show, :create, :destroy ] do
        # ── Memberships ────────────────────────────────────────────────────
        # POST   /api/v1/conversations/:conversation_id/memberships
        # DELETE /api/v1/conversations/:conversation_id/memberships/:id
        resources :memberships, only: [ :create, :destroy ]

        # ── Messages ───────────────────────────────────────────────────────
        # GET    /api/v1/conversations/:conversation_id/messages       (paginated)
        # POST   /api/v1/conversations/:conversation_id/messages
        # PATCH  /api/v1/conversations/:conversation_id/messages/:id   (own only)
        # DELETE /api/v1/conversations/:conversation_id/messages/:id   (own or admin)
        resources :messages, only: [ :index, :create, :update, :destroy ]

        # ── Calls ──────────────────────────────────────────────────────────
        # POST   /api/v1/conversations/:conversation_id/calls           (initiate)
        # GET    /api/v1/conversations/:conversation_id/calls/active    (join late)
        # DELETE /api/v1/conversations/:conversation_id/calls/:id       (end call)
        resources :call_sessions, only: [ :create, :destroy ], path: "calls" do
          collection { get :active }
        end
      end

      # ── Reactions ──────────────────────────────────────────────────────────
      # Flat (not nested under messages) because the client sends
      # { message_id: } in the body — avoids ugly double-nesting in the URL.
      # POST   /api/v1/reactions
      # DELETE /api/v1/reactions/:id
      resources :reactions, only: [ :create, :destroy ]
    end
  end

  # ─── Health check ─────────────────────────────────────────────────────────
  get "up" => "rails/health#show", as: :rails_health_check
end
