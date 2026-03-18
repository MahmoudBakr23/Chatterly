class CallSessionPolicy < ApplicationPolicy
  # create? — any conversation member can initiate a call
  # TODO: def create? = true

  # destroy? — only the initiator can end the call
  # TODO: def destroy? = record.initiator_id == user.id
end
