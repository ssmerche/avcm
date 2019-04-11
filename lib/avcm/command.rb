# frozen_string_literal: true

require 'thor'

# Command for managing the clip library
class Avcm::Command < Thor
  def initialize(*args)
    super(*args)
    command = args.last[:current_command]&.name&.strip
    if AvClipManager::CONFIG.empty? &&
       !['help', 'version', nil, ''].include?(command)
      puts "Config not found at #{AvClipManager::CONFIG_PATH}"
      Kernel.exit(false)
    end
    @library = Avcm::ClipLibrary.new
  end

  desc 'version', 'Print avcm version'
  def version
    puts AvClipManager::VERSION
  end

  desc 'config', 'Print config location and values'
  def config
    puts AvClipManager::CONFIG_PATH
    puts AvClipManager::CONFIG
  end

  desc 'export', 'Export database to .looper file'
  def export
    stats = @library.shuffled_looper('master.looper', -1, strategy: :export)
    puts "#{stats[:row_count]} entries exported to master.looper"
  end

  desc 'shuffle [FILENAME] [NUM]',
       'Create a shuffled playlist of NUM clips at FILENAME'
  option :strategy, type: :string, default: 'default'
  def shuffle(filename = 'rand.looper', num = 30)
    strategy = options[:strategy].downcase.to_sym
    error = nil
    unless Avcm::Sql::STRATEGIES.include?(strategy)
      strategy = :discovery
      error = :invalid_strategy
    end
    stats = @library.shuffled_looper(filename, num, strategy: strategy)
    spec = Avcm::Template.spec_for_shuffle(filename, strategy, error,
                                           stats[:row_count])
    puts Avcm::Template.from_spec(stats, spec)
  end

  STATUS_SPEC = lambda { |stats|
    [["__dir__: #{__dir__}"], ["__FILE__: #{__FILE__}"],
     %i[count rated tagged], %i[unrated untagged tagged_and_unrated],
     %i[untagged_and_unrated tagged_and_rated], ["Tags: #{stats[:tags]}"],
     ['Ratings'], [:ratings], ["#{stats[:looper_count]} clips in looper files"]]
  }

  desc 'status', 'Prints status of the library'
  def status
    stats = @library.status.merge(looper_count: @library.entries.length)
    (STATUS_SPEC >> Avcm::Template.method(:from_spec).curry.call(stats) >>
      method(:puts)).call(stats)
  end

  desc 'import [NAME]', 'Import entries from .looper files into NAME database'
  option :force_overwrite, type: :boolean, default: false, aliases: :f,
                           desc: 'Replace database entries with looper entries'
  def import(name: 'master.sqlite')
    (@library.method(:load) >> Avcm::Template::IMPORT >> method(:puts))
      .call(name, options[:force_overwrite])
  end

  desc 'suggest [NUM]', 'Avcm::Suggest NUM files to create clips from'
  def suggest(num: 1)
    (Avcm::Suggest.method(:suggest) >> Avcm::Template::SUGGEST >>
     method(:puts)).call(num: num)
  end

  desc 'rehash', 'Rehash the .looper entries and update NAME database'
  def rehash(name: 'master.sqlite')
    db = Avcm::Db.new
    db.rehash
    db.close
    puts "Rehashed entries into #{name}"
  end
end
