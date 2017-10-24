# frozen_string_literal: true

module GehirnDns
  class Error < StandardError
  end

  class ValidationError < Error
  end

  class UnrequestableError < Error
  end

  class RequestError < Error
    attr_reader :path, :body

    def initialize(path, body = nil)
      @path = path
      @body = body

      message = "path: #{@path}"
      message += ", response: #{@body}" if @body
      super(message)
    end
  end

  class UnauthorizedError < RequestError
  end

  class ForbiddenError < RequestError
  end

  class NotFoundError < RequestError
  end

  class RequestToDeletedError < RequestError
  end

  class RequestTimeoutError < RequestError
  end
end
