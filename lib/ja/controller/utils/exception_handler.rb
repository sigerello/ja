require "active_support/concern"
require "ja/exception_wrapper"
require "ja/error/record_not_found"

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

          wrapper.log_exception

          data = {
            errors: [{
              status: wrapper.status_code,
              title:  Rack::Utils::HTTP_STATUS_CODES.fetch(wrapper.status_code, Rack::Utils::HTTP_STATUS_CODES[500]),
              details: exception.message, #TODO: don't show details for 500 errors
            }]
          }
          render json: data, status: status
        end

      private

        def ja_rethrow_exception
          yield
        rescue ActiveRecord::RecordNotFound => e
          raise Ja::Error::RecordNotFound.new e.message
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
