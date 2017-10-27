# frozen_string_literal: true

require 'net/http'
require 'json'

require 'gehirn_dns/resource'
require 'gehirn_dns/resource/preset'
require 'gehirn_dns/resource/record'
require 'gehirn_dns/resource/record_set'
require 'gehirn_dns/resource/version'
require 'gehirn_dns/resource/zone'
require 'gehirn_dns/version'

module GehirnDns
  class Client
    attr_accessor :base_uri, :token, :secret

    DEFAULT_USER_AGENT = "gehirndns-ruby/#{::GehirnDns::VERSION}"

    def initialize(options = {})
      @base_uri = ::URI.parse(options[:base_uri] || ENV.fetch('GEHIRN_DNS_BASE_URL', DEFAULT_BASE_URL))
      @token = options[:token] || ENV.fetch('GEHIRN_DNS_API_TOKEN')
      @secret = options[:secret] || ENV.fetch('GEHIRN_DNS_API_SECRET')
      @user_agent = options[:user_agent] || ENV.fetch('GEHIRN_DNS_USER_AGENT', DEFAULT_USER_AGENT)
    end

    def get(path)
      execute :get, path
    end

    def post(path, body)
      execute :post, path, body
    end

    def put(path, body)
      execute :put, path, body
    end

    def delete(path)
      execute :delete, path
    end

    def base_uri=(base_uri)
      @base_uri = ::URI.parse(base_uri)
    end

    def inspect
      %Q(#<#{self.class}:#{object_id} @base_uri=#{@base_uri.inspect}, @secret=<HIDDEN>, @token=<HIDDEN>, @user_agent=#{@user_agent.inspect}>)
    end

    private

    def execute(method, path, body = nil)
      response = request(method, path, body)

      body = if response.header['Content-Type']&.start_with? 'application/json'
               JSON.parse(response.body, symbolize_names: true)
             else
               response.body
             end

      case response.code.to_i
      when 200..299
        body
      when 401
        raise UnauthorizedError, 'Expects API key has expired or not valid'
      when 403
        raise ForbiddenError, "Expects API key doesn't have a permission to request"
      when 404
        raise NotFoundError.new(path, body)
      when 408
        raise ReuqestTimeoutError.new(path, body)
      when 500..599
        raise RequestError.new(path, body)
      else
        raise RequestError.new(path, body)
      end
    end

    def request_class_for(method)
      case method.downcase.to_sym
      when :get
        ::Net::HTTP::Get
      when :post
        ::Net::HTTP::Post
      when :put
        ::Net::HTTP::Put
      when :delete
        ::Net::HTTP::Delete
      else
        raise ArgumentError, "method: #{method} isn't allowed."
      end
    end

    def http
      http = ::Net::HTTP.new(@base_uri.host, @base_uri.port)
      http.use_ssl = true
      http
    end

    def request(method, path, body = nil)
      body = body.to_json if body.is_a? Hash

      request_path = Pathname(@base_uri.path) + path.to_s

      request = request_class_for(method).new(request_path.to_s)

      if body
        request.content_type = 'application/json'
        request.body = body
      end

      request.basic_auth(@token, @secret)
      http.request(request)
    end
  end
end
