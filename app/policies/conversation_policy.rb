class ConversationPolicy < ApplicationPolicy
  # show? — only members can view a conversation
  def show? = member?
  # create? — any authenticated user can start a conversation
  def create? = true
  # destroy? — only the creator or an admin member can delete
  def destroy?
    record.created_by_id == user.id || admin_member?
  end
  # manage_members? — used in MembershipsController (add/remove members)
  # Only admin members of the conversation can manage membership.
  def manage_members?
    admin_member?
  end

  private

  # Checks if the current user is a member of this conversation.
  # members is a has_many :through, so .exists? hits the DB once (no preload needed).
  def member?
    record.members.exists?(user.id)
  end
  # Checks if the current user has the :admin role in this conversation.
  def admin_member?
    record.conversation_members.exists?(user_id: user.id, role: :admin)
  end
end
