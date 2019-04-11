# frozen_string_literal: true

require 'charlock_holmes'

# Common functions for importing from playlists
module Avcm::Import
  module_function

  DETECTOR = CharlockHolmes::EncodingDetector.new
  CONVERTER = CharlockHolmes::Converter

  def encode(text)
    encoding = DETECTOR.detect(text)[:encoding]
    text = CONVERTER.convert(text, encoding, 'UTF-8') if encoding != 'UTF-8'
    text.delete("\xEF\xBB\xBF", '') # get rid of BOM
  end
end
