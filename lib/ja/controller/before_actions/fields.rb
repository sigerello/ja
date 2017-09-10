require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Fields
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_fields
        end

      private

        def ja_fields
          [ja_resource_class, *ja_resource_class.ja_relationships.map{ |r| r[:klass] }].inject({}) do |h, klass|
            h[klass.ja_type] = klass.ja_fields
            h
          end
        end

        def ja_restricted_fields
          [ja_resource_class, *ja_resource_class.ja_relationships.map{ |r| r[:klass] }].inject({}) do |h, klass|
            h[klass.ja_type] = klass.ja_restricted_fields
            h
          end
        end

        # TODO: consider to raise errors when user requests restricted includes
        def ja_set_fields
          ja_options[:fields] = {}

          controller_fields = ja_fields
          controller_restricted_fields = ja_restricted_fields

          [ja_resource_class, *ja_resource_class.ja_relationships.map{ |r| r[:klass] }].each do |klass|
            fields = params[:fields][klass.ja_type].split(",") rescue []
            fields = controller_fields[klass.ja_type] unless fields.size > 0
            fields = klass.ja_fields unless fields.is_a?(Array)

            restricted_fields = controller_restricted_fields[klass.ja_type]
            restricted_fields = klass.ja_restricted_fields unless restricted_fields.is_a?(Array)

            obj = klass.new
            fields.delete_if{ |m| !obj.respond_to?(m) }
            restricted_fields.delete_if{ |m| !obj.respond_to?(m) }

            fields = fields.map(&:to_sym) - restricted_fields.map(&:to_sym) - klass.ja_relationship_names

            ja_options[:fields][klass.ja_type] = fields
          end
        end

      end
    end
  end
end
