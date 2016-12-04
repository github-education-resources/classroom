# frozen_string_literal: true
module GitHubClassroom
  def self.videos
    return @classroom_videos if defined?(@classroom_videos)
    yaml_data = YAML.load(File.read(Rails.root.join('config', 'videos.yml')))
    @classroom_videos = HashWithIndifferentAccess.new(yaml_data)
  end
end
