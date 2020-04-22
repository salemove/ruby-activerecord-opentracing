RSpec.describe ActiveRecord::OpenTracing::SqlSanitizer do
  def sanitize(sql, database_engine: :postgres)
    described_class.new(sql, database_engine: database_engine).to_s
  end

  def expect_faster_than(target_seconds)
    t1 = ::Time.now
    result = yield
    t2 = ::Time.now
  
    actual_time = t2.to_f - t1.to_f
    expect(actual_time < target_seconds).to be_truthy
    result
  end

  it 'bails out to prevent long running instrumentation if the query is too long' do
    raw_sql = " " * 1001

    sanitized_sql = sanitize(raw_sql)
    expected_sql = ''

    expect(sanitized_sql).to eq(expected_sql)
  end

  context 'postgres' do
    it 'test_postgres_simple_select_of_first' do
      raw_sql = %q|SELECT  "users".* FROM "users"  ORDER BY "users"."id" ASC LIMIT 1|

      sanitized_sql = sanitize(raw_sql, database_engine: :postgres)
      expected_sql = %q|SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT 1|

      expect(sanitized_sql).to eq(expected_sql)
    end

    it 'test_postgres_where' do
      raw_sql = %q|SELECT "users".* FROM "users" WHERE "users"."name" = $1  [["name", "chris"]]|

      sanitized_sql = sanitize(raw_sql, database_engine: :postgres)
      expected_sql = %q|SELECT "users".* FROM "users" WHERE "users"."name" = ?|

      expect(sanitized_sql).to eq(expected_sql)
    end

    it 'test_postgres_strips_literals' do
      # Strip strings
      raw_sql = %q|SELECT "users".* FROM "users" INNER JOIN "blogs" ON "blogs"."user_id" = "users"."id" WHERE (blogs.title = 'hello world')|

      sanitized_sql = sanitize(raw_sql, database_engine: :postgres)
      expected_sql = %q|SELECT "users".* FROM "users" INNER JOIN "blogs" ON "blogs"."user_id" = "users"."id" WHERE (blogs.title = ?)|

      expect(sanitized_sql).to eq(expected_sql)
    end

    it 'test_postgres_strips_after_where' do
      raw_sql = %q|SELECT DISTINCT ON (flagged_traces.metric_name) flagged_traces.metric_name, "flagged_traces"."trace_id", "flagged_traces"."trace_type", "flagged_traces"."trace_occurred_at", flagged_traces.details ->> 'uri' as uri, (flagged_traces.details ->> 'n_sum_millis')::float as potential_savings, (flagged_traces.details ->> 'n_count')::float as num_queries FROM "flagged_traces" WHERE "flagged_traces"."app_id" = 5 AND "flagged_traces"."trace_type" = 'Request' AND ("flagged_traces"."trace_occurred_at" BETWEEN '2019-04-17 12:28:00.000000' AND '2019-04-18 12:28:00.000000') AND "flagged_traces"."flag_type" = 'nplusone' ORDER BY "flagged_traces"."metric_name" ASC, potential_savings DESC|

      sanitized_sql = sanitize(raw_sql, database_engine: :postgres)
      expected_sql = %q|SELECT DISTINCT ON (flagged_traces.metric_name) flagged_traces.metric_name, "flagged_traces"."trace_id", "flagged_traces"."trace_type", "flagged_traces"."trace_occurred_at", flagged_traces.details ->> 'uri' as uri, (flagged_traces.details ->> 'n_sum_millis')::float as potential_savings, (flagged_traces.details ->> 'n_count')::float as num_queries FROM "flagged_traces" WHERE "flagged_traces"."app_id" = ? AND "flagged_traces"."trace_type" = ? AND ("flagged_traces"."trace_occurred_at" BETWEEN ? AND ?) AND "flagged_traces"."flag_type" = ? ORDER BY "flagged_traces"."metric_name" ASC, potential_savings DESC|

      expect(sanitized_sql).to eq(expected_sql)
    end

    it 'test_postgres_strips_subquery_strings' do
      raw_sql = %q|"SELECT 'orgs'.* FROM "orgs" WHERE  "orgs"."name" = 'Scout' AND "orgs"."created_by_user_id" IN (SELECT 'users'.'id' FROM "users" WHERE (id > AVG(id)) AND "type" = 'USER' AND "created_at" BETWEEN '2019-04-17 12:28:00.000000' AND '2019-04-18 12:28:00.000000')"|

      sanitized_sql = sanitize(raw_sql, database_engine: :postgres)
      expected_sql = %q|"SELECT 'orgs'.* FROM "orgs" WHERE "orgs"."name" = ? AND "orgs"."created_by_user_id" IN (SELECT 'users'.'id' FROM "users" WHERE (id > AVG(id)) AND "type" = ? AND "created_at" BETWEEN ? AND ?)"|
      
      expect(sanitized_sql).to eq(expected_sql)
    end

    it 'test_postgres_strips_integers' do
      # Strip integers
      raw_sql = %q|SELECT "blogs".* FROM "blogs" WHERE (view_count > 10)|

      sanitized_sql = sanitize(raw_sql, database_engine: :postgres)
      expected_sql = %q|SELECT "blogs".* FROM "blogs" WHERE (view_count > ?)|

      expect(sanitized_sql).to eq(expected_sql)
    end

    it 'test_postgres_collapse_in_clause' do
      raw_sql = %q|SELECT "blogs".* FROM "blogs" WHERE id IN (?, ?, ?)|

      sanitized_sql = sanitize(raw_sql, database_engine: :postgres)
      expected_sql = %q|SELECT "blogs".* FROM "blogs" WHERE id IN (?)|

      expect(sanitized_sql).to eq(expected_sql)
    end

    it 'test_postgres_collapse_in_clause_performacne' do
      raw_sql = 'SELECT "users".* FROM "users" WHERE "users"."id" IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)'

      sanitized_sql = expect_faster_than(0.01) { sanitize(raw_sql, database_engine: :postgres) }
      expected_sql = %q|SELECT "users".* FROM "users" WHERE "users"."id" IN (?)|

      expect(sanitized_sql).to eq(expected_sql)
    end

  end

  it 'test_mysql_where' do
    raw_sql = %q|SELECT `users`.* FROM `users` WHERE `users`.`name` = ?  [["name", "chris"]]|

    sanitized_sql = sanitize(raw_sql, database_engine: :mysql)
    expected_sql = %q|SELECT `users`.* FROM `users` WHERE `users`.`name` = ?|

    expect(sanitized_sql).to eq(expected_sql)
  end

  it 'test_mysql_limit' do
    raw_sql = %q|SELECT  `blogs`.* FROM `blogs`  ORDER BY `blogs`.`id` ASC LIMIT 1|

    sanitized_sql = sanitize(raw_sql, database_engine: :mysql)
    expected_sql = %q|SELECT  `blogs`.* FROM `blogs`  ORDER BY `blogs`.`id` ASC LIMIT 1|

    expect(sanitized_sql).to eq(expected_sql)
  end

it 'test_mysql_collpase_in_clause_performance' do
  raw_sql = 'SELECT `users`.* FROM `users` WHERE `users`.`id` IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)'

  sanitized_sql = expect_faster_than(0.01) { sanitize(raw_sql, database_engine: :mysql) }
  expected_sql = %q|SELECT `users`.* FROM `users` WHERE `users`.`id` IN (?)|

  expect(sanitized_sql).to eq(expected_sql)
end

  it 'test_mysql_literals 1' do
    raw_sql = %q|SELECT `blogs`.* FROM `blogs` WHERE (title = 'abc')|

    sanitized_sql = sanitize(raw_sql, database_engine: :mysql)
    expected_sql = %q|SELECT `blogs`.* FROM `blogs` WHERE (title = ?)|

    expect(sanitized_sql).to eq(expected_sql)
  end

  it 'test_mysql_literals 2' do
    raw_sql = %q|SELECT `blogs`.* FROM `blogs` WHERE (title = "abc")|

    sanitized_sql = sanitize(raw_sql, database_engine: :mysql)
    expected_sql = %q|SELECT `blogs`.* FROM `blogs` WHERE (title = ?)|

    expect(sanitized_sql).to eq(expected_sql)
  end

  it 'test_mysql_quotes' do
    raw_sql = %q|INSERT INTO `users` VALUES ('foo', 'b\'ar')|

    sanitized_sql = sanitize(raw_sql, database_engine: :mysql)
    expected_sql = %q|INSERT INTO `users` VALUES (?, ?)|

    expect(sanitized_sql).to eq(expected_sql)
  end

  it 'test_scrubs_invalid_encoding' do
    raw_sql = "SELECT `blogs`.* FROM `blogs` WHERE (title = 'a\255c')".force_encoding('UTF-8')
    expect(raw_sql.valid_encoding?).to be_falsy

    sanitized_sql = sanitize(raw_sql, database_engine: :mysql)
    expected_sql = %q|SELECT `blogs`.* FROM `blogs` WHERE (title = ?)|

    expect(sanitized_sql).to eq(expected_sql)
  end
end
