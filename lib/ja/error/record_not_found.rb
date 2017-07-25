
module Ja
  module Error
    # class RecordNotFound < ActiveRecord::RecordNotFound
    class RecordNotFound < StandardError
      # TODO: show more detailed message - use info from params
    end
  end
end
