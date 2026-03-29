class AddCallSessionIdToMessages < ActiveRecord::Migration[8.1]
  def change
    # call_session_id links a call-type message back to its CallSession.
    # No FK constraint: messages is a partitioned table and PostgreSQL does not
    # support foreign keys that reference a partitioned table's child partitions.
    # We enforce referential integrity at the application layer (CallLogService).
    add_column :messages, :call_session_id, :bigint
    add_index :messages, :call_session_id
  end
end
