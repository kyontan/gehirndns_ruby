# frozen_string_literal: true

module GehirnDns
  class Client
    def zones
      response = get 'zones'
      response.map { |zone| Zone.new(zone, client: self, base_path: '') }
    end

    def zone(id: nil, name: nil)
      if id
        # name is ignored
        response = get "zones/#{id}"
        zone = Zone.new(response, client: self, base_path: '')
      else
        zone = zones.find { |z| z.name == name }
      end

      raise NotFoundError if zone.nil?

      zone
    end
  end

  class Zone < Resource
    attr_reader :id, :name, :editable, :created_at, :current_version_id, :last_modified_at

    def current_version
      response = http_get "versions/#{current_version_id}"
      Version.new(response, zone: self, client: @client, base_path: resource_path)
    end

    def current_record_sets(**args)
      current_version.record_sets(**args)
    end

    def current_record_set(**args)
      current_version.record_set(**args)
    end

    def versions
      response = http_get 'versions'
      response.map { |version| Version.new(version, zone: self, client: @client, base_path: resource_path) }.sort_by!(&:last_modified_at)
    end

    def version(id: nil, name: nil)
      raise ArgumentError, "passing both id and name is not allowed" if id && name
      raise ArgumentError, "missing keyword: id or name" if !id && !name

      if id
        response = http_get "versions/#{id}"
        version = Version.new(response, zone: self, client: @client, base_path: resource_path)
      else
        version = versions.find { |v| v.name == name }
      end

      raise NotFoundError if version.nil?

      version
    end

    def presets
      response = http_get 'presets'
      response.map { |preset| Preset.new(preset, client: @client, base_path: resource_path) }.sort_by!(&:applied_at)
    end

    alias migrations presets
  end
end
