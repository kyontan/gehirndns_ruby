# frozen_string_literal: true

module GehirnDns
  class Record
    attr_reader :id, :record_set

    RECORD_TYPES = %i(A AAAA CNAME MX NS SRV TXT).freeze
    RECORD_FIELDS = {
      A:     %i(address),
      AAAA:  %i(address),
      CNAME: %i(cname),
      MX:    %i(prio exchange),
      NS:    %i(nsdname),
      SRV:   %i(target port weight),
      TXT:   %i(data),
    }.freeze

    def initialize(record, record_set: nil)
      @record_set = record_set

      attribute_names(type: record_set&.type).each do |key|
        instance_variable_set(:"@#{key}", record[key])
      end

      redefine_attributes
    end

    def record_set=(record_set)
      @record_set = record_set

      redefine_attributes

      @record_set << self if @record_set
    end

    def to_h
      attributes
    end

    def attributes(type: @record_set&.type)
      Hash[attribute_names(type: type).map { |attr| [attr, instance_variable_get(:"@#{attr}")] }]
    end

    def attribute_names(type: @record_set&.type)
      return RECORD_FIELDS.values.flatten unless RECORD_FIELDS.key? type
      RECORD_FIELDS[type]
    end

    def delete
      @record_set.delete_record(self)
    end

    private

    def all_attriubute_names
      RECORD_FIELDS.values.flatten.uniq
    end

    def redefine_attributes(type: @record_set&.type)
      required_attrs = attribute_names(type: type)

      all_attriubute_names.each do |attr|
        inst_var_sym = :"@#{attr}"
        setter_sym = "#{attr}="

        if required_attrs.include? attr
          define_singleton_method(attr) { instance_variable_get(inst_var_sym) }

          define_singleton_method(setter_sym) do |value|
            instance_variable_set(inst_var_sym, value)
            @record_set&.update
          end
        else
          remove_instance_variable(inst_var_sym) if instance_variable_defined?(inst_var_sym)
          singleton_class.class_eval do
            undef_method attr, setter_sym if respond_to?(setter_sym)
          end
        end
      end
    end
  end
end
