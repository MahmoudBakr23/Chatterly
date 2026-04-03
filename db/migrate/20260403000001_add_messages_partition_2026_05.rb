class AddMessagesPartition202605 < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS messages_2026_05
        PARTITION OF messages
        FOR VALUES FROM ('2026-05-01 00:00:00+00')
                      TO ('2026-06-01 00:00:00+00');
    SQL
  end

  def down
    execute "DROP TABLE IF EXISTS messages_2026_05;"
  end
end
