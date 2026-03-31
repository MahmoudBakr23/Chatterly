class MessagePolicy < ApplicationPolicy
  # create? — any conversation member can send a message
  # (membership is already verified by set_conversation in MessagesController)
  def create? = true
  # update? — only the author can edit their own message
  def update? = record.user_id == user.id
  # destroy? — author or conversation admin can soft-delete
  def destroy?
    record.user_id == user.id || admin_of_conversation?
  end

  private

  def admin_of_conversation?
    record.conversation.conversation_members.exists?(user_id: user.id, role: :admin)
  end
end
