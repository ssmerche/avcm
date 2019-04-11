# frozen_string_literal: true

require 'sequel'
require 'digest'

# Manage database of looper clips
class Avcm::Db
  STATS_QUERY_PARAMS = {
    tagged_and_unrated: { exclude: { tags: nil }, cond: { rating: nil } },
    untagged_and_unrated: { cond: { tags: nil, rating: nil } },
    unrated: { cond: { rating: nil } }, count: {},
    untagged: { cond: { tags: nil } },
    tagged_and_rated: { exclude: { tags: nil, rating: nil } },
    ratings_counts: { col: [:rating], count: ['clips.rating'],
                      exclude: { rating: nil },
                      group: [:rating], desc: :rating }
  }.freeze

  attr_reader :new_db
  alias new? new_db

  def initialize(path: 'master.sqlite')
    @new_db = !File.exist?(path)
    @sequel = Sequel.sqlite(path)
    @sequel[Avcm::Sql::SCHEMA]
    @sql = Avcm::Query.new(@sequel)
    @clips = @sequel[:clips]
    @columns = Avcm::Playlist::MpcLooper::COLUMNS
    @find_seq = @sequel[:clips].select(*@columns).where(sequence_id: :$id)
                               .order(Sequel.asc(:sequence_index))
                               .prepare(:select, :find_seq)
  end

  def load_entry(entry, hash, overwrite = false)
    @sequel[Avcm::Sql::INSERT, *entry, hash]
  rescue Sequel::UniqueConstraintViolation
    @sequel[Avcm::Sql::UPDATE, *entry[1..-1], hash, entry[0]] if overwrite
  end

  def hash(entry)
    Digest::MD5.hexdigest(entry.to_s)
  end

  def load(entries, overwrite = false)
    hshs = @clips.map(:hash)
    @sequel.transaction do
      entries.reject { |e| hshs.include?(hash(e)) }
             .each { |e| load_entry(e, hash(e), overwrite) }
    end
    query
  end

  def rehash
    @sequel.transaction do
      @clips.select(:id, :start_time, :end_time, :path, :hash).each do |e|
        hsh = hash(e.values_at(:start_time, :end_time, :path))
        next if hsh == e[:hash]

        @clips.where(id: e[:id]).update(hash: hsh)
      end
    end
  end

  def insert_sequences(strategy, entries, inserted_seqs = [])
    entries.reduce([]) do |acc, entry|
      if !entry.last || strategy == :sequences
        acc + [entry[0...-1]]
      elsif inserted_seqs.include?(entry.last)
        acc
      else
        inserted_seqs << entry.last
        acc + @find_seq.call(id: entry.last).map(&:values)
      end
    end
  end

  def entries(num = 30, strategy = :discovery)
    return @clips.map(@columns) if strategy == :export

    es = Avcm::Sql::STRATEGIES[strategy].reduce([]) do |acc, sql|
      if acc.length == num
        acc
      else
        acc + @sequel[sql % @sql.list(acc), num - acc.length].map(&:values)
      end
    end
    insert_sequences(strategy, es)
  end

  def query(opts = {})
    opts = { col: [], count: ['*'], cond: {}, exclude: {}, distinct: false,
             group: [], asc: nil, desc: nil }.merge(opts)
    if opts[:group].empty?
      @sql.query(opts).single_value
    else
      @sql.query(opts).map(&:values)
    end
  end

  def tags
    @clips.select(:tags).where(Sequel.~(tags: nil) & Sequel.~(tags: ''))
          .distinct.map(:tags).flat_map { |t| t.split(',') }.uniq
  end

  def stats
    result = STATS_QUERY_PARAMS.inject({}) do |acc, (k, v)|
      acc.merge(k => query(v))
    end
    result[:tags] = tags
    result.merge(tagged: result[:count] - result[:untagged],
                 rated: result[:count] - result[:unrated])
  end
end
