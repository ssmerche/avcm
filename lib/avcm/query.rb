# frozen_string_literal: true

require 'sequel'

# Build SQL queries
class Avcm::Query
  SEQUEL_MOCK_CLASS = Sequel.mock.class

  def initialize(sql = Sequel.mock)
    @sql = sql
  end

  def order(stmt, asc: nil, desc: nil)
    return stmt if asc.nil? && desc.nil?

    stmt = stmt.order(Sequel.asc(asc)) unless asc.nil?
    stmt = stmt.order(Sequel.desc(desc)) unless desc.nil?
    stmt
  end

  def exclude(stmt, exc)
    (exc || []).empty? ? stmt : stmt.where(Sequel.negate(exc))
  end

  def group(stmt, grp)
    (grp || []).empty? ? stmt : stmt.group(*grp)
  end

  def select(stmt, col: [], count: ['*'], cond: {})
    col += count.map { |c| Sequel.function(:count, c) }
    stmt.select(*col).where(cond)
  end

  def query(opts)
    stmt = select(@sql[:clips], opts.slice(:col, :count, :cond))
    stmt = exclude(stmt, opts[:exclude])
    stmt = group(stmt, opts[:group])
    stmt = order(stmt, opts.slice(:asc, :desc))
    @sql.is_a?(SEQUEL_MOCK_CLASS) ? stmt.sql : stmt
  end

  def list(vals)
    return '' if vals.empty?

    vals.flat_map { |v| "'#{v[0]}'" }.join(',')
  end
end
