class CallSessionPolicy < ApplicationPolicy
  # create? — any conversation member can initiate a call.
  def create? = true

  # accept? — any member who is NOT the initiator can accept.
  # The initiator cannot accept their own call — it makes no semantic sense
  # and would incorrectly stamp started_at before anyone joins.
  def accept? = record.initiator_id != user.id

  # decline? — same rule as accept; the initiator should use destroy? to end
  # a call they started, not decline it.
  def decline? = record.initiator_id != user.id

  # destroy? — only the initiator can end the call.
  def destroy? = record.initiator_id == user.id
end
