# frozen_string_literal: true

require 'time'
require 'pathname'

module GehirnDns
  class Resource
    def initialize(attrs = {}, client:, base_path: '')
      attrs.each do |key, value|
        if key.to_s.end_with? '_at'
          # rubocop:disable Lint/HandleExceptions
          begin
            value = Time.parse(value)
          rescue ArgumentError
            # do nothing
          end
          # rubocop:enable Lint/HandleExceptions
        end

        instance_variable_set(:"@#{key}", value)
      end

      @client = client
      @base_path = Pathname(base_path)
    end

    protected

    def plulal_name
      self.class.to_s.split('::').last.downcase + 's'
    end

    def resource_path
      @base_path + plulal_name + @id.to_s
    end

    def http_get(*args)
      execute(:get, *args)
    end

    def http_post(*args)
      execute(:post, *args)
    end

    def http_put(*args)
      execute(:put, *args)
    end

    def http_delete(*args)
      response = execute(:delete, *args)
      mark_as_deleted!
      response
    end

    private

    def mark_as_deleted!
      @deleted = true
    end

    def execute(method, path, *args)
      path = resource_path + path unless path.start_with? '/'

      raise RequestToDeletedError, path if @deleted

      @client.send(method, path, *args)
    end
  end
end
