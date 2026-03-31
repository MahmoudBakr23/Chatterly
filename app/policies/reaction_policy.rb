class ReactionPolicy < ApplicationPolicy
  # create? — any authenticated user (membership enforced via message's conversation)
  def create? = true
  # destroy? — only the user who added the reaction can remove it
  def destroy? = record.user_id == user.id
end
