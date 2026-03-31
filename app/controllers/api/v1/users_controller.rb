module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: %i[show update]
      # ─── index ──────────────────────────────────────────────────────────────
      # GET /api/v1/users?search=alice
      # Returns users matching the search query.
      # Pundit: any authenticated user can search — no policy check needed here.
      def index
        users = User.where("username ILIKE :q OR display_name ILIKE :q",
                            q: "%#{params[:search]}%")
        render json: UserBlueprint.render(users, view: :public)
      end

      # ─── me ─────────────────────────────────────────────────────────────────
      # GET /api/v1/users/me
      # Returns the current user's full profile including email.
      # current_user is set by Devise from the JWT (via BaseController#authenticate_user!).
      def me
        render json: UserBlueprint.render(current_user, view: :with_email)
      end

      # ─── show ───────────────────────────────────────────────────────────────
      # GET /api/v1/users/:id
      # Returns a user's public profile (no email).
      # .find raises RecordNotFound → caught by ApplicationController → 404.
      def show
        render json: UserBlueprint.render(@user, view: :public)
      end

      # ─── update ─────────────────────────────────────────────────────────────
      # PATCH /api/v1/users/:id
      # Update display_name or avatar_url. Pundit blocks editing other users.
      def update
        authorize @user
        if @user.update(user_params)
          render json: UserBlueprint.render(@user, view: :with_email)
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # Strong params — only allow fields the user is allowed to self-update.
      # Email and username changes are intentionally excluded (bigger flow needed).
      def user_params
        params.require(:user).permit(:display_name, :avatar_url)
      end

      def set_user
        @user = User.find(params[:id])
      end
    end
  end
end
