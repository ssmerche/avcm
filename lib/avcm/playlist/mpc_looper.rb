# frozen_string_literal: true

require 'csv'

# Read and write Media Player Classic Looper
# (http://www.gullswingmedia.com/mpc-hc-looper.html) .looper files
module Avcm::Playlist::MpcLooper
  module_function

  SOURCE_LOOPERS = AvClipManager::CONFIG.fetch(:loopers, []).freeze
  CSV_FORMAT = { col_sep: '|', row_sep: "\r\n" }.freeze
  COLUMNS = %i[name start_time end_time path].freeze

  def entries
    SOURCE_LOOPERS.flat_map do |filename|
      unless File.exist?(filename)
        puts "WARNING: #{filename} not found"
        next
      end
      text = File.read(filename)
      CSV.parse(Avcm::Import.encode(text), CSV_FORMAT)
    end.uniq
  end

  def dump(entries, name = 'rand.looper')
    CSV.open(name, 'wb', CSV_FORMAT) do |rand_looper|
      entries.each { |row| rand_looper << row }
    end
    entries.length
  end
end
