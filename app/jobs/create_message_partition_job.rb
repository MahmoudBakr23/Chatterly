class CreateMessagePartitionJob < ApplicationJob
  queue_as :default

  # Runs on the 25th of each month (see config/sidekiq.rb) to pre-create
  # the following month's messages partition before it's needed.
  # Using IF NOT EXISTS makes it safe to run manually at any time.
  def perform
    target     = Time.current.next_month
    year       = target.year
    month      = target.month
    table_name = format("messages_%04d_%02d", year, month)
    from       = Time.utc(year, month, 1).iso8601
    to         = Time.utc(year, month, 1).next_month.iso8601

    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{conn.quote_table_name(table_name)}
        PARTITION OF messages
        FOR VALUES FROM (#{conn.quote(from)})
                      TO (#{conn.quote(to)});
    SQL

    Rails.logger.info("[CreateMessagePartitionJob] Partition #{table_name} ensured (#{from} → #{to})")
  end
end
