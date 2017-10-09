
module Ja
  module Error

    # class RecordNotFound < ActiveRecord::RecordNotFound
    class RecordNotFound < StandardError
      # TODO: show more detailed message - use info from params
    end

    # class InvalidIncludeParam < StandardError
    #   attr_reader :status_code

    #   def initialize(message, klass, rel)
    #     @klass = klass
    #     @rel = rel
    #     @status_code = 400
    #     message = "Invalid include param \"#{@rel}\" for \"#{@klass}\" class"
    #     super(message)
    #   end

    # end

    # class RestrictedIncludeParam < StandardError
    #   attr_reader :status_code

    #   def initialize(message, klass, rel)
    #     @klass = klass
    #     @rel = rel
    #     @status_code = 400
    #     message = "Restricted include param \"#{@rel}\" for \"#{@klass}\" class"
    #     super(message)
    #   end
    # end

  end
end
