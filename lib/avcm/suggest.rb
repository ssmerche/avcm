# frozen_string_literal: true

# Generate a randomized list of clips
module Avcm::Suggest
  module_function

  VID_GLOB = '*.{mp4,mkv,ogm,avi,wmv,flv}'
  SKIP = Avcm::Playlist::MpcLooper.entries.map do |e|
    File.join(AvClipManager::CONFIG[:root], *e[-1].split('\\')[1..-1])
  end + AvClipManager::CONFIG[:excludes]

  def suggestions(from: AvClipManager::CONFIG[:dirs], skip: SKIP)
    (from.flat_map do |dir|
      Dir.glob("#{dir}**/#{VID_GLOB}") + Dir.glob("#{dir}#{VID_GLOB}")
    end - skip).uniq
  end

  def suggest(num: 1, skip: SKIP)
    vids = suggestions(skip: skip)
    [vids.sample(num), vids.length]
  end
end
