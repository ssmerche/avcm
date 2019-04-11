# frozen_string_literal: true

require 'zeitwerk'
require 'yaml'
loader = Zeitwerk::Loader.for_gem
loader.setup

# Top-level module
module AvClipManager
  class Error < StandardError; end
  CONFIG_PATH = ENV.fetch('AVCM_CONFIG', 'avcm.yml')
  CONFIG = if File.exist?(CONFIG_PATH)
             YAML.load_file(CONFIG_PATH).transform_keys(&:to_sym).freeze
           else
             {}.freeze
           end
end
