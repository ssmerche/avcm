# frozen_string_literal: true

require 'forwardable'

# Clip library management
class Avcm::ClipLibrary
  extend Forwardable

  attr_reader :entries

  def initialize
    @entries = Avcm::Playlist::MpcLooper.entries
  end

  def shuffled_looper(filename, num, strategy: :discovery)
    @db = Avcm::Db.new
    row_count = Avcm::Playlist::MpcLooper.dump(
      @db.entries(num, strategy.to_sym), filename
    )
    stats = @db.stats.merge(row_count: row_count)
    stats
  end

  def status
    @db = Avcm::Db.new
    stats = @db.stats
    stats
  end

  def load(name, overwrite = false)
    @db = Avcm::Db.new(path: name)
    result = { before: @db.query, looper_entries: @entries.length }
    result[:after] = @db.load(@entries, overwrite)
    result.merge(diff: result[:after] - result[:before],
                 fail: result[:looper_entries] - result[:after])
  end
end
