# frozen_string_literal: true

module GehirnDns
  class Client
    def zones
      response = get 'zones'
      response.map { |zone| Zone.new(zone, client: self, base_path: '') }
    end

    def zone(name:)
      zone = zones.find { |z| z.name == name }

      raise NotFoundError if zone.nil?

      zone
    end
  end

  class Zone < Resource
    attr_reader :id, :name, :editable, :created_at, :current_version_id, :last_modified_at

    def current_version
      response = http_get "versions/#{current_version_id}"
      Version.new(response, client: @client, base_path: resource_path)
    end

    def record_sets
      current_version.record_sets
    end

    def versions
      response = http_get 'versions'
      response.map { |version| Version.new(version, client: @client, base_path: resource_path) }.sort_by!(&:last_modified_at)
    end

    def presets
      response = http_get 'presets'
      response.map { |preset| Preset.new(preset, client: @client, base_path: resource_path) }.sort_by!(&:applied_at)
    end

    alias migrations presets
  end
end
