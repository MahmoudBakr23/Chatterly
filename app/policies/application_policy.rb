class ApplicationPolicy
  # ApplicationPolicy is the base class for all Pundit policies.
  # Every resource policy inherits from here.
  #
  # How Pundit works:
  #   authorize @record           → calls policy(@record).action_name?
  #   policy_scope(Model)         → calls Scope#resolve to filter records
  #   authorize @record, :custom? → calls policy(@record).custom?
  #
  # If any method returns false → Pundit raises NotAuthorizedError
  # → ApplicationController rescues it → 403 response
  #
  # Pundit injects two variables into every policy instance:
  #   @user   — the current_user (from the controller)
  #   @record — the resource being authorized

  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  # All actions default to false (deny) unless overridden in the subclass.
  # This is the safest default — explicit allow beats implicit deny.
  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false

  # Scope filters a collection down to what the current user is allowed to see.
  # Default: nothing (raise NotImplementedError to force subclasses to define it).
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError,
            "#{self.class} must implement #resolve"
    end
  end
end
