# frozen_string_literal: true

# rubocop:disable Metrics/LineLength

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'av_clip_manager/version'

Gem::Specification.new do |spec|
  spec.name          = 'av_clip_manager'
  spec.version       = AvClipManager::VERSION
  spec.authors       = ['Scott Smerchek']
  spec.email         = ['av_clip_manager@protonmail.com']

  spec.summary       = 'Audio/Video Clip Manager'
  spec.description   = 'Audio/Video Clip Manager'
  spec.homepage      = 'http://dev.local'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://localhost:9292'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://dev.local'
    spec.metadata['changelog_uri'] = 'https://dev.local'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6.0'

  %w[bundler rake bump pry benchmark-ips rubocop ruby-prof object_shadow].each do |d|
    spec.add_development_dependency d
  end
  %w[thor sqlite3 sequel charlock_holmes zeitwerk].each do |d|
    spec.add_dependency d
  end
end

# rubocop:enable Metrics/LineLength
