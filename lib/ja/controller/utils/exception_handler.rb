require "active_support/concern"
require "ja/exception_wrapper"

module Ja
  module Controller
    module Utils
      module ExceptionHandler
        extend ActiveSupport::Concern

        def ja_render_exception exception=nil
          exception = request.get_header("action_dispatch.exception") unless exception

          backtrace_cleaner = request.get_header("action_dispatch.backtrace_cleaner")
          wrapper = Ja::ExceptionWrapper.new(backtrace_cleaner, exception)

          status = wrapper.status_code
          status = 500 unless Rack::Utils::HTTP_STATUS_CODES.keys.include?(status)

          wrapper.log_exception

          error = {
            status: status,
            title:  Rack::Utils::HTTP_STATUS_CODES[status],
          }
          error[:detail] = exception.message unless status == 500

          render json: { errors: [error] }, status: status
        end

      private

        def ja_reraise_exception
          yield
        rescue ActiveRecord::RecordNotFound => e
          # raise Ja::Error::RecordNotFound.new e.message
          raise Ja::Error::RecordNotFound.new "Resource not found"
        end

        # def ja_recursively_raise(c=0, max=5)
        #   Rails.logger.fatal "raise #{c}"
        #   raise "Level #{c}"
        # rescue => e
        #   if c < max
        #     ja_recursively_raise(c + 1, max)
        #   else
        #     raise
        #   end
        # end

      end
    end
  end
end
