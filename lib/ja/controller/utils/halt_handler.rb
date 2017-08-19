require "active_support/concern"

module Ja
  module Controller
    module Utils
      module HaltHandler
        extend ActiveSupport::Concern

        included do
          around_action :ja_catch_halt
        end

      private

        def ja_catch_halt
          data = catch :halt do
            yield and return
          end
          ja_render_halted data
        end

        def halt data
          throw :halt, data
        end

        def ja_render_halted data
          status = data[:status].to_i
          status = 500 unless Rack::Utils::HTTP_STATUS_CODES.keys.include?(status)
          if data[:errors] && data[:errors].is_a?(Array)
            result = { errors: data[:errors] }
          else
            error = {
              status: status,
              title:  Rack::Utils::HTTP_STATUS_CODES[status],
            }
            error[:detail] = data[:detail] if data[:detail]
            result = { errors: [error] }
          end
          render json: result, status: status
        end

      end
    end
  end
end
