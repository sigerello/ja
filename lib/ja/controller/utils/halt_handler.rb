require "active_support/concern"

module Ja
  module Controller
    module Utils
      module HaltHandler
        extend ActiveSupport::Concern

        included do
          around_action :catch_halt
        end

      private

        def catch_halt
          status, data = catch :halt do
            yield
            return
          end
          render json: data, status: status
        end

        def halt(data)
          throw :halt, format_halted_success(data)
        end

        def halt!(data)
          throw :halt, format_halted_error(data)
        end

        def format_halted_success(data = {})
          status = data.delete(:status).to_i
          status = 200 unless Rack::Utils::HTTP_STATUS_CODES.keys.include?(status)
          [status, data]
        end

        def format_halted_error(data = {})
          status = data.delete(:status).to_i
          status = 500 unless Rack::Utils::HTTP_STATUS_CODES.keys.include?(status)
          data[:title] ||= Rack::Utils::HTTP_STATUS_CODES[status]
          data = { errors: [data] } unless data[:errors]
          [status, data]
        end

      end
    end
  end
end
