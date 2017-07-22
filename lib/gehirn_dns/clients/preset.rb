# frozen_string_literal: true

module GehirnDns
  class Preset < Resource
    attr_reader :id, :name, :is_completed, :created_at, :applied_at, :completed_at, :next_version_id, :prev_version_id

    def next_version
      version = http_get "../../versions/#{@next_version_id}"
      path = resource_path + '../../'
      Version.new(version, client: @client, base_path: path)
    end

    def prev_version
      version = http_get "../../versions/#{@next_version_id}"
      path = resource_path + '../../'
      Version.new(version, client: @client, base_path: path)
    end
  end
end
