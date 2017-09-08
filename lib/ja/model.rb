require "active_support/concern"

module Ja
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def ja_type
        self.to_s.demodulize.tableize.to_sym
      end

      def ja_pk
        :id
      end

      def ja_fields
        return @ja_fields if defined?(@ja_fields)
        @ja_fields = self.attribute_names.map(&:to_sym) - [self.ja_pk] - self.ja_relationships.map{ |r| r[:foreign_key] }.compact
      end

      def ja_restricted_fields
        []
      end

      def ja_include
        # return @ja_include if defined?(@ja_include)
        # @ja_include = self.ja_relationship_names.map(&:to_s)
        []
      end

      def ja_restricted_include
        []
      end

      def ja_sort
        # TODO: implement sorting by related resources
        [{ :created_at => :desc }]
      end

      def ja_relationships
        return @ja_relationships if defined?(@ja_relationships)
        @ja_relationships = self.reflect_on_all_associations.map do |association|
          type = :to_one if [ActiveRecord::Reflection::HasOneReflection, ActiveRecord::Reflection::BelongsToReflection].include? association.class
          type = :to_many if [ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasAndBelongsToManyReflection].include? association.class

          next unless type

          rel = {
            type: type,
            name: association.name,
            klass: association.klass,
          }
          rel[:foreign_key] = association.foreign_key.to_sym if type == :to_one
          rel
        end
      end

      def ja_relationship_names
        self.ja_relationships.map{ |r| r[:name] }
      end

      def ja_check_include!(inst, path)
        paths = path.split(".")
        if paths.size == 1
          # TODO: format proper error response
          raise Ja::Error::InvalidIncludeParam.new(nil, inst.class, paths[0]) unless inst.respond_to?(paths[0])
        elsif paths.size > 1
          self.ja_check_include!(inst, paths[0])
          inst = inst.class.ja_relationships.select{ |r| r[:name].to_s == paths[0] }[0][:klass].new
          self.ja_check_include!(inst, paths[1..-1].join("."))
        end
      end

      def ja_populate_include!(res, objs, path, options = {})
        paths = path.split(".")
        [*objs].each do |obj|
          if paths.size == 1
            [*obj.send(paths[0])].each do |rec|
              # _debug "--> obj #{obj.class}:#{obj.try(:id)} - #{path}"
              res << rec.ja_resource_object(options)
            end
          elsif paths.size > 1
            ja_populate_include!(res, obj, paths[0], options)
            rel = obj.class.ja_relationships.select{ |r| r[:name].to_s == paths[0] }[0][:name]
            obj = obj.send(rel)
            ja_populate_include!(res, obj, paths[1..-1].join("."), options)
          end
        end
      end

    end

    def ja_resource_uid
      "#{self.class.ja_type}:#{self.send(self.class.ja_pk)}"
    end

    def ja_resource_identifier_object(options = {})
      res = {}
      res[:id] = self.send(self.class.ja_pk).to_s
      res[:type] = self.class.ja_type
      res
    end

    def ja_resource_object(options = {})
      res = ja_resource_identifier_object(options)
      res = ja_build_resource_object_attributes(res, options)
      res = ja_build_resource_object_relationships(res, options)
      res
    end

    # TODO: implement
    def ja_included_resource_objects(options = {})
      # _debug options
      res = []
      # return nil if options[:skip_include]
      # inc = options[:include]
      options = options.dup
      inc = options.delete(:include)
      inc.each { |path| self.class.ja_populate_include!(res, self, path, options) }
      res
    end

    def ja_error_objects(options = {})
      options.reverse_merge!(pointer_path: "/data/attributes/")
      self.errors.as_json(full_messages: true).map do |field, errors|
        errors.map do |error|
          {
            detail: error,
            source: { pointer: "#{options[:pointer_path]}#{field}" }
          }
        end
      end.flatten
    end

  private

    def ja_build_resource_object_attributes(res, options = {})
      fields = self.class.ja_fields
      fields = options[:fields][self.class.ja_type] if options[:fields] && options[:fields][self.class.ja_type].is_a?(Array)
      fields.delete_if{ |m| !self.respond_to?(m) }
      methods = fields - self.class.attribute_names

      res[:attributes] = self.as_json(only: fields, methods: methods).symbolize_keys
      res
    end

    def ja_build_resource_object_relationships(res, options = {})
      # return res if options[:skip_relationships]
      self.class.ja_relationships.each do |relationship|
        if relationship[:type] == :to_one
          res[:relationships] ||= {}
          res[:relationships][relationship[:name]] = {}
          res[:relationships][relationship[:name]][:data] = self.send(relationship[:name]).ja_resource_identifier_object rescue nil
        elsif relationship[:type] == :to_many
          next unless (options[:include] || []).map{ |path| path.split(".")[0] }.include?(relationship[:name].to_s)
          res[:relationships] ||= {}
          res[:relationships][relationship[:name]] = {}
          res[:relationships][relationship[:name]][:data] = []
          self.send(relationship[:name]).each do |obj|
            res[:relationships][relationship[:name]][:data] << obj.ja_resource_identifier_object
          end
        end
      end
      res
    end

  end
end
