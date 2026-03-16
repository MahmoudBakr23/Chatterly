class AddParentMessageToMessages < ActiveRecord::Migration[8.1]
  def change
    # No foreign_key: messages PK is composite (id, created_at) — can't FK to id alone.
    add_column :messages, :parent_message_id, :bigint
    add_index :messages, :parent_message_id
  end
end
