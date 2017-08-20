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
        self.column_names.map(&:to_sym) - [self.ja_pk, :password_digest]
      end

      def ja_sort
        [{ :created_at => :desc }]
      end
    end

    def ja_resource_object options={}
      res = {}
      res[:id] = self[self.class.ja_pk]
      res[:type] = self.class.ja_type
      res[:attributes] = ja_build_resource_object_attributes options[:fields]
      res
    end

  private

    def ja_build_resource_object_attributes params_fields
      fields = self.class.ja_fields
      fields = params_fields if params_fields.is_a?(Array)
      fields.delete_if{ |m| !self.respond_to?(m) }
      methods = fields - self.class.column_names
      self.as_json(only: fields, methods: methods).symbolize_keys
    end

  end
end
