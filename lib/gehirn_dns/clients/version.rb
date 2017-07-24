# frozen_string_literal: true

module GehirnDns
  class Version < Resource
    attr_reader :id, :name, :editable, :created_at, :last_modified_at

    # TODO: not fqdn matching
    def record_sets(name: nil, type: nil)
      type = type.upcase.to_sym if type

      respnose = http_get 'records'
      respnose \
        .map { |record_set| RecordSet.new(record_set, editable: @editable, version: self, client: @client, base_path: resource_path) } \
        .select { |record_set| (name.nil? || record_set.name == name) && (type.nil? || record_set.type == type) }
    end

    def record_set(name:, type:)
      record_sets(name: name, type: type).first
    end

    def clone(name:)
      response = http_post '../', name: name
      Version.new(response, client: @client, base_path: resource_path + '../../')
    end

    def delete
      http_delete '.'
    end

    def activate!
      migrate
    end

    alias migrate! activate!

    # if prev version is nil, the latest version will set
    def migrate(name: nil, applied_at: nil)
      payload = {
        applied_at: applied_at ? applied_at.getutc.strftime('%FT%TZ') : nil,
        name: name,
        next_version_id: @id
      }.compact

      http_post '../../presets', payload
    end

    alias create_migration migrate
  end
end
