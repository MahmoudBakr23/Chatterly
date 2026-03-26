class ConversationPolicy < ApplicationPolicy
  # show? — only members can view a conversation
  # TODO: def show? = member?
  def show? = member?
  # create? — any authenticated user can start a conversation
  # TODO: def create? = true
  def create? = true
  # destroy? — only the creator or an admin member can delete
  # TODO: def destroy?
  #         record.created_by_id == user.id || admin_member?
  #       end
  def destroy?
    record.created_by_id == user.id || admin_member?
  end
  # manage_members? — used in MembershipsController (add/remove members)
  # Only admin members of the conversation can manage membership.
  # TODO: def manage_members?
  #         admin_member?
  #       end
  def manage_members?
    admin_member?
  end

  private

  # Checks if the current user is a member of this conversation.
  # members is a has_many :through, so .exists? hits the DB once (no preload needed).
  # TODO: def member?
  #         record.members.exists?(user.id)
  #       end
  def member?
    record.members.exists?(user.id)
  end
  # Checks if the current user has the :admin role in this conversation.
  # TODO: def admin_member?
  #         record.conversation_members.exists?(user_id: user.id, role: :admin)
  #       end
  def admin_member?
    record.conversation_members.exists?(user_id: user.id, role: :admin)
  end
end
