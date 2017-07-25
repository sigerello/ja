require "active_support/concern"

module Ja
  module Model
    extend ActiveSupport::Concern

    class_methods do

      def ja_type
        self.to_s.demodulize.tableize
      end

      def ja_pk
        :id
      end

    end

  end
end
