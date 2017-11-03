# frozen_string_literal: true

module GehirnDns
  class Version < Resource
    attr_reader :id, :name, :editable, :created_at, :last_modified_at, :zone

    def initialize(attrs = {}, zone:, client: nil, base_path: '')
      @zone = zone

      super(attrs, client: client, base_path: base_path)
    end

    # TODO: not fqdn matching
    def record_sets(name: nil, type: nil)
      type = type.upcase.to_sym if type

      respnose = http_get 'records'
      respnose \
        .map { |record_set| RecordSet.new(record_set, editable: @editable, version: self, client: @client, base_path: resource_path) } \
        .select { |record_set| (name.nil? || record_set.name == name) && (type.nil? || record_set.type == type) }
    end

    def record_set(id: nil, name: nil, type: nil)
      raise ArgumentError, 'passing both id and name is not allowed' if id && (name || type)
      raise ArgumentError, 'missing keyword: one of id, name, type is required' if !id && !(name || type)

      if id
        respnose = http_get "records/#{id}"
        RecordSet.new(respnose, editable: @editable, version: self, client: @client, base_path: resource_path)
      else
        record_sets(name: name, type: type).first
      end
    end

    def create(name:, base: nil)
      response = http_post '../', { name: name, base: base }.compact
      Version.new(response, client: @client, base_path: resource_path + '../../')
    end

    def clone(name:)
      create(name: name, base: @id)
    end

    def delete
      http_delete '.'
    end

    def activate!
      migrate(name: nil, applied_at: nil)
    end

    def <<(record_set)
      raise ArgumentError unless record_set.is_a? RecordSet
      record_set.version = self
    end

    alias migrate! activate!

    # if prev version is nil, the latest version will set
    def migrate(name:, applied_at:)
      payload = {
        applied_at: applied_at ? applied_at.getutc.strftime('%FT%TZ') : nil,
        name: name,
        next_version_id: @id,
      }.compact

      response = http_post '../../presets', payload
      Preset.new(response, client: @client, base_path: resource_path + '../../')
    end

    alias create_migration migrate
  end
end
