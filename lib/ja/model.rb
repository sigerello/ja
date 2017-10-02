require "active_support/concern"

module Ja
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def ja_type
        return @ja_type if defined?(@ja_type)
        @ja_type = self.to_s.demodulize.tableize.to_sym
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
        []
      end

      def ja_restricted_include
        []
      end

      # TODO: implement sorting by related resources
      def ja_sort
        [{ :created_at => :desc }]
      end

      def ja_relationships
        return @ja_relationships if defined?(@ja_relationships)
        @ja_relationships = self.reflect_on_all_associations.map do |association|
          type = :has_one if association.instance_of?(ActiveRecord::Reflection::HasOneReflection) # to_one
          type = :belongs_to if association.instance_of?(ActiveRecord::Reflection::BelongsToReflection) # to_one
          type = :has_many if association.instance_of?(ActiveRecord::Reflection::HasManyReflection) # to_many
          type = :has_and_belongs_to_many if association.instance_of?(ActiveRecord::Reflection::HasAndBelongsToManyReflection) # to_many

          next unless type
          next if association.options[:polymorphic]

          rel = {
            type: type,
            name: association.name,
            klass: association.klass,
          }
          rel[:foreign_key] = association.foreign_key.to_sym if [:belongs_to].include?(type)
          rel
        end.compact
      end

      def ja_relationship_names
        return @ja_relationship_names if defined?(@ja_relationship_names)
        @ja_relationship_names = self.ja_relationships.map{ |r| r[:name] }
      end

      def ja_included_resource_objects(objs, options = {})
        options = options.dup
        inc = options.delete(:include) || []
        included_resources_uids = [*objs].map(&:ja_resource_uid)
        build_included = lambda do |res, objs, path, options, included_resources_uids|
          options ||= {}
          included_resources_uids ||= []
          paths = path.split(".")
          [*objs].each do |obj|
            if paths.size == 1
              [*obj.send(paths[0])].each do |rec|
                unless included_resources_uids.include?(rec.ja_resource_uid)
                  res << rec.ja_resource_object(options)
                  included_resources_uids << rec.ja_resource_uid
                end
              end
            elsif paths.size > 1
              build_included.call(res, obj, paths[0], options, included_resources_uids)
              obj = obj.send(paths[0])
              path = paths[1..-1].join(".")
              build_included.call(res, obj, path, options, included_resources_uids)
            end
          end
        end
        inc.inject([]) { |res, path| build_included.call(res, objs, path, options, included_resources_uids); res }
      end

      def ja_preload(options = {})
        rels = options[:include] || []
        @ja_preload ||= Hash.new do |h, k|
          k = k + ja_relationships.select { |r| r[:type] == :belongs_to }.map { |r| r[:name].to_s }
          k = k.uniq
          build_preload = lambda do |path|
            paths = path.split(".")
            if paths.size == 1
              path.to_sym
            elsif paths.size > 1
              path = paths[1..-1].join(".")
              { paths[0].to_sym => build_preload.call(path) }
            end
          end
          preload = k.map { |path| build_preload.call(path) }
          req_deep_merge = lambda do |res, v|
            res = { res => {} } unless res.is_a?(Hash)
            v = { v => {} } unless v.is_a?(Hash)
            res.deep_merge!(v) { |k, v1, v2| req_deep_merge.call(v1, v2) }
          end
          h[k] = preload.inject({}) { |res, v| req_deep_merge.call(res, v); res }
        end
        @ja_preload[rels]
      end

      def ja_include_map(options = {})
        inc = options[:include] || []
        @ja_include_map ||= Hash.new do |h, k|
          populate_include_map = lambda do |res, obj, path|
            res ||= {}
            paths = path.split(".")
            if paths.size == 1
              if obj.respond_to?(paths[0])
                res[obj.class.ja_type] ||= []
                res[obj.class.ja_type] << paths[0].to_sym unless res[obj.class.ja_type].include?(paths[0].to_sym)
              else
                # TODO: format proper error response
                raise Ja::Error::InvalidIncludeParam.new(nil, obj.class, paths[0]) unless obj.respond_to?(paths[0])
              end
            elsif paths.size > 1
              populate_include_map.call(res, obj, paths[0])
              obj = obj.class.ja_relationships.select { |r| r[:name].to_s == paths[0] }[0][:klass].new rescue nil
              path = paths[1..-1].join(".")
              populate_include_map.call(res, obj, path) if obj
            end
          end
          obj = self.new
          h[k] = k.inject({}) { |res, path| populate_include_map.call(res, obj, path); res }
        end
        @ja_include_map[inc]
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

    def ja_error_objects(options = {})
      options = options.dup.reverse_merge!(pointer_path: "/data/attributes/")
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
      include_map = self.class.ja_include_map(options)
      # _debug "include_map: ", include_map
      included_resource_types = include_map[self.class.ja_type] || [] rescue []

      self.class.ja_relationships.each do |relationship|
        next if relationship[:type] != :belongs_to && !included_resource_types.include?(relationship[:name])

        if [:has_one, :belongs_to].include?(relationship[:type])
          res[:relationships] ||= {}
          res[:relationships][relationship[:name]] = {}
          res[:relationships][relationship[:name]][:data] = self.send(relationship[:name]).ja_resource_identifier_object rescue nil
        elsif [:has_many, :has_and_belongs_to_many].include?(relationship[:type])
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
