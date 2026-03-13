class AllowNullCreatedByOnConversations < ActiveRecord::Migration[8.1]
  def change
    # Allow NULL on created_by_id so that when a user is deleted,
    # their created conversations survive with created_by_id set to NULL
    # rather than being destroyed along with all their members and messages.
    # null: false stays valid at creation time — this only affects post-deletion state.
    change_column_null :conversations, :created_by_id, true
  end
end
