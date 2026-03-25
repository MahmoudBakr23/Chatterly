class ApplicationController < ActionController::API
  include Pundit::Authorization

  # ─── Global error handlers ────────────────────────────────────────────────
  # These rescue_from blocks catch errors from any controller action and return
  # clean JSON instead of leaking stack traces or Rails HTML error pages.
  #
  # NotAuthorizedError → Pundit throws this when policy denies access → 403
  # RecordNotFound     → ActiveRecord throws this on .find() miss → 404
  #
  # TODO: rescue_from Pundit::NotAuthorizedError, with: :forbidden
  # TODO: rescue_from ActiveRecord::RecordNotFound,  with: :not_found
  rescue_from Pundit::NotAuthorizedError,   with: :forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  # TODO: def forbidden
  #         render json: { error: "Not authorized" }, status: :forbidden
  #       end
  def forbidden
    render json: { error: "Not authorized" }, status: :forbidden
  end

  # TODO: def not_found
  #         render json: { error: "Not found" }, status: :not_found
  #       end
  def not_found
    render json: { error: "Not found" }, status: :not_found
  end
end
