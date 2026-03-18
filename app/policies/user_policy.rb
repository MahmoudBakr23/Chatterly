class UserPolicy < ApplicationPolicy
  # show? — any authenticated user can view public profiles
  # TODO: def show?  = true

  # update? — only the user themselves can edit their profile
  # TODO: def update? = user == record
end
