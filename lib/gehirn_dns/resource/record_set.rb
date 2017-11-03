# frozen_string_literal: true

module GehirnDns
  class RecordSet < Resource
    attr_reader :id, :type, :enable_alias, :editable, :version, :name, :alias_to, :ttl, :records

    include Enumerable

    def initialize(record_set, editable: true, version: nil, client: nil, base_path: '')
      @id = record_set[:id]
      @name = record_set[:name]
      @type = record_set[:type]&.upcase&.to_sym
      @ttl = record_set[:ttl]
      @enable_alias = record_set[:enable_alias] || false
      @editable = editable # API can ignore it

      singleton_class.class_eval { attr_writer :id, :type, :enable_alias } unless @id

      @version = version

      if @enable_alias
        @alias_to = record_set[:alias_to]
        @records = []
      else
        @alias_to = nil
        @records = (record_set[:records] || []).map { |r| Record.new(r, record_set: self) }
      end

      super(client: client, base_path: base_path)
    end

    def each
      @record_set.each { |r| yield r }
    end

    def name=(name)
      @name = name
      update
    end

    def alias_to=(alias_to)
      @alias_to = alias_to
      @enable_alias = true
      @records = []
      update
    end

    def ttl=(ttl)
      raise StandardError, "alias record can't set ttl" if @enable_alias
      @ttl = ttl
      update
    end

    def version=(version)
      raise StandardError, "Can't edit version already has" if @id

      @version = version
      @client = version.client
      @base_path = version.resource_path

      begin
        response = http_post '../records', to_h
        @id = response[:id]
        @name = response[:name]
      rescue StandardError => e # failed to add record set, revert
        @version = nil
        @client = nil
        @base_path = nil
        raise e
      end
    end

    # append record
    def <<(record)
      return self if @records.include?(record) || equal?(record.record_set)

      record = Record.new(record) unless record.is_a? RecordSet

      raise ArgumentError, 'record is already member of a RecordSet' if record.record_set != self

      record.record_set = self

      @enable_alias = false
      @alias_to = nil
      @records << record

      begin
        update
      rescue StandardError => e # failed to add record, revert
        @records.delete(record)
        record.record_set = nil
        raise e
      end
    end

    def records=(records)
      @records = records.map { |r| Record.new(r, record_set: self) }
      @enable_alias = false

      update
    end

    def to_h
      {
        id: @id,
        type: @type,
        enable_alias: @enable_alias,
        name: @name,
        ttl: @ttl,
        records: @enable_alias ? nil : @records.map(&:to_h),
        alias_to: @enable_alias ? @alias_to : nil,
      }.compact
    end

    def update
      response = http_put '.', to_h if @client && @version
      @name = response[:name]
      self
    end

    def delete
      raise UnrequestableError, "record set doen't have a version" unless @client && @version
      http_delete '.'
    end

    def delete_record(record)
      raise ArgumentError, "record isn't member of record set" unless @records.include?(record) || equal?(record.record_set)
      raise ValidationError, "Can't delete only record of record set" if @records.size == 1
      @records.delete(record)
      update
    end

    protected

    def plulal_name
      'records'
    end
  end
end
