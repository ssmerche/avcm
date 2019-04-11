# frozen_string_literal: true

# Console output templates
module Avcm::Template
  module_function

  IMPORT = lambda { |stats|
    str = <<~STR
      #{stats[:looper_entries]} entries in .looper files
      #{stats[:before]} entries in database before load
      #{stats[:after]} entries in database after load
      #{stats[:diff]} entries added
    STR
    if stats[:fail].positive?
      str += "#{stats[:fail]} entries failed to load into the database"
    end
    str
  }

  SUGGEST = lambda { |result|
    "#{result.first.join("\n")}\n#{result.last} unclipped files"
  }

  TAGS = lambda { |stats|
    { tags: stats[:tags].join(', '),
      ratings: stats[:ratings_counts].map { |r| r.join(': ') }.join(', ') }
  }

  DESCS = {
    unrated: '%s clips unrated', untagged: '%s clips untagged',
    untagged_and_unrated: '%s clips untagged and unrated',
    tagged_and_rated: '%s clips tagged and rated',
    count: '%s clips in library', rated: '%s clips rated',
    tagged: '%s clips tagged', tags: 'Tags: %s',
    tagged_and_unrated: '%s clips tagged but not rated'
  }.freeze

  STRATEGY_ERROR = <<~STR
    %s is an invalid strategy
    Valid strategies are: #{Avcm::Sql::STRATEGIES.keys}
    Falling back to discovery strategy
  STR

  def from_spec(stats, spec)
    stats.merge!(Avcm::Template::TAGS.call(stats))
    spec.map do |line|
      line.map do |key|
        if key.is_a?(String)
          key
        else
          Avcm::Template::DESCS.fetch(key, stats[key]) % stats[key]
        end
      end.join(', ')
    end.join("\n")
  end

  def spec_for_shuffle(filename, strategy, error, rows)
    spec = [[`cat #{filename}`], [''],
            ["#{strategy} strategy used"],
            ["#{rows} entries in #{filename}"],
            %i[unrated untagged]]
    if error == :invalid_strategy
      spec[2] = [Avcm::Template::STRATEGY_ERROR % strategy]
    end
    spec
  end
end
