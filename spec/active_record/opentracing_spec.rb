RSpec.describe ActiveRecord::OpenTracing do
  let(:tracer) { OpenTracingTestTracer.build }

  before do
    config = {
      adapter: 'sqlite3',
      database: 'tracer-test'
    }
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS users'
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id integer PRIMARY KEY,
        name text NOT NULL
      );
    SQL
  end

  # rubocop:disable RSpec/LeakyConstantDeclaration
  class User < ActiveRecord::Base
  end
  # rubocop:enable RSpec/LeakyConstantDeclaration

  it 'records sql select query' do
    User.first # load table schema, etc
    described_class.instrument(tracer: tracer)
    User.first

    expect(tracer.spans.count).to eq(1)
    span = tracer.spans.last
    expect(span.operation_name).to eq('User Load')
    expect(span.tags).to eq(
      'component' => 'ActiveRecord',
      'span.kind' => 'client',
      'db.instance' => 'tracer-test',
      'db.statement' => 'SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?',
      'db.cached' => false,
      'db.type' => 'sql',
      'peer.address' => 'sqlite3:///tracer-test'
    )
  end

  it 'uses active span as parent when present' do
    User.first # load table schema, etc
    described_class.instrument(tracer: tracer)

    parent_span = tracer.start_active_span('parent_span') { User.first }.span

    expect(tracer.spans.count).to eq(2)
    span = tracer.spans.last
    expect(span.context.parent_id).to eq(parent_span.context.span_id)
  end

  it 'records custom sql query' do
    User.first # load table schema, etc
    described_class.instrument(tracer: tracer)
    ActiveRecord::Base.connection.execute 'SELECT COUNT(1) FROM users'

    expect(tracer.spans.count).to eq(1)
    span = tracer.spans.last
    expect(span.operation_name).to eq('sql.query')
    expect(span.tags).to eq(
      'component' => 'ActiveRecord',
      'span.kind' => 'client',
      'db.instance' => 'tracer-test',
      'db.statement' => 'SELECT COUNT(1) FROM users',
      'db.cached' => false,
      'db.type' => 'sql',
      'peer.address' => 'sqlite3:///tracer-test'
    )
  end

  it 'records sql errors' do
    User.first # load table schema, etc
    described_class.instrument(tracer: tracer)

    thrown_exception = nil
    begin
      ActiveRecord::Base.connection.execute 'SELECT * FROM users WHERE email IS NULL'
    rescue StandardError => e
      thrown_exception = e
    end

    expect(tracer.spans.count).to eq(1)
    span = tracer.spans.last
    expect(span.operation_name).to eq('sql.query')
    expect(span.tags).to eq(
      'component' => 'ActiveRecord',
      'span.kind' => 'client',
      'db.instance' => 'tracer-test',
      'db.statement' => 'SELECT * FROM users WHERE email IS NULL',
      'db.cached' => false,
      'db.type' => 'sql',
      'peer.address' => 'sqlite3:///tracer-test',
      'error' => true
    )
    expect(span.logs).to include(
      a_hash_including(
        event: 'error',
        'error.kind': thrown_exception.class.to_s,
        'error.object': thrown_exception,
        message: thrown_exception.message,
        stack: thrown_exception.backtrace.join("\n")
      )
    )
  end
end
