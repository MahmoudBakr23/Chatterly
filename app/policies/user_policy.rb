class UserPolicy < ApplicationPolicy
  # show? — any authenticated user can view public profiles
  def show? = true

  # update? — only the user themselves can edit their profile
  def update? = user == record
end
