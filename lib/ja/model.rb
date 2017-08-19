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

      def ja_fields
        # TODO: remove relationship attributes
        self.column_names.map(&:to_sym) - [:id, :password_digest]
      end
    end

    def ja_resource_object options={}
      res = {}
      res[:id] = self[self.class.ja_pk]
      res[:type] = self.class.ja_type

      fields = self.class.ja_fields
      fields = options[:fields] if options[:fields].is_a?(Array)
      fields.map!(&:to_s)

      # TODO: allow virtual attributes
      res[:attributes] = self.attributes.slice(*fields).symbolize_keys
      res
    end

  end
end
