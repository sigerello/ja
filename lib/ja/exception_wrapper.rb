require "action_dispatch/middleware/exception_wrapper"

module Ja
  class ExceptionWrapper < ActionDispatch::ExceptionWrapper

    attr_reader :exceptions_stack

    def initialize(backtrace_cleaner, exception)
      @exceptions_stack = get_exceptions_stack(exception)
      super
    end

    def get_exceptions_stack(exception)
      stack = []
      current_exception = exception
      while current_exception do
        stack << current_exception
        current_exception = current_exception.cause
      end
      stack
    end

    def original_exception(exception)
      @exceptions_stack.each do |e|
        return e if @@rescue_responses.has_key?(e.class.name)
      end
      exception
    end

    def log_exception
      trace = self.application_trace
      trace = self.framework_trace if trace.empty?

      Rails.logger.fatal "  "
      @exceptions_stack.reverse.each_with_index do |e, i|
        prefix = e == @exception ? "**" : "*"
        Rails.logger.fatal "#{prefix} #{e.class} (#{e.message})"
      end
      Rails.logger.fatal @exception.annoted_source_code.join("\n") if @exception.respond_to?(:annoted_source_code)
      Rails.logger.fatal "  "
      Rails.logger.fatal trace.join("\n")
    end
  end
end
