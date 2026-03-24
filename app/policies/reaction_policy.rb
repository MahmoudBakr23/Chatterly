class ReactionPolicy < ApplicationPolicy
  # create? — any authenticated user (membership enforced via message's conversation)
  # TODO: def create? = true
  def create? = true
  # destroy? — only the user who added the reaction can remove it
  # TODO: def destroy? = record.user_id == user.id
  def destroy? = record.user_id == user.id
end
