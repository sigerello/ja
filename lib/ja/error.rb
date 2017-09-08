
module Ja
  module Error

    # class RecordNotFound < ActiveRecord::RecordNotFound
    class RecordNotFound < StandardError
      # TODO: show more detailed message - use info from params
    end

    class InvalidIncludeParam < StandardError
      def initialize(message, klass, relationship)
        @klass = klass
        @relationship = relationship
        message = "Invalid include param: there is no \"#{@relationship}\" relationship for class \"#{@klass}\""
        super(message)
      end
    end
  end
end
