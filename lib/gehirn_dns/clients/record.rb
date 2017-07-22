# frozen_string_literal: true

module GehirnDns
  class RecordSet < Resource
    attr_reader :id, :type, :enable_alias, :editable
    attr_accessor :name, :alias_to, :ttl, :records

    include Enumerable

    def initialize(record_set, editable: true, client:, base_path: '')
      @id = record_set[:id]
      @name = record_set[:name]
      @type = record_set[:type].upcase.to_sym
      @ttl = record_set[:ttl]
      @enable_alias = record_set[:enable_alias]
      @editable = editable # API can ignore it

      if @enable_alias
        @alias_to = record_set[:alias_to]
      else
        @records = record_set[:records].map { |r| Record.new(r, record_set: self) }
      end

      super(client: client, base_path: base_path)
    end

    def each
      @record_set.each { |r| yield r }
    end

    def resource_path
      @base_path + plulal_name
    end

    def name=(name)
      @name = name
      update
    end

    def alias_to=(alias_to)
      @alias_to = alias_to
      @enable_alias = true
      update
    end

    def ttl=(ttl)
      @ttl = ttl
      update
    end

    # append record
    def <<(record)
      # TODO
    end

    def records=(records)
      @records = records.map { |r| Record.new(r) }
      update
    end

    private

    def update
      # TODO:
    end
  end

  class Record
    def initialize(record, record_set: nil)
      @record_set = record_set

      required_attribtues.each do |key|
        instance_variable_set(:"@#{key}", record[key])
        singleton_class.class_eval { attr_accessor key }

        # TODO: define setter
      end
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    def required_attribtues
      case @record_set&.type
      when :A, :AAAA then %i(address)
      when :CNAME    then %i(cname)
      when :MX       then %i(prio exchange)
      when :NS       then %i(nsdname)
      when :SRV      then %i(target port weight)
      when :TXT      then %i(data)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
