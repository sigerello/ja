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

      # TODO: implement sorting by related resources
      def ja_sort
        [{ :created_at => :desc }]
      end

      def ja_allowed_fields(context = {})
        self.attribute_names.map(&:to_sym) - [self.ja_pk] - self.ja_direct_relationships.map{ |r| r[:foreign_key] }.compact
      end

      def ja_default_fields(context = {})
        self.ja_allowed_fields(context)
      end

      def ja_fields(context = {})
        @ja_fields ||= Hash.new do |result, ctx|
          type = self.ja_type
          allowed_fields = self.ja_allowed_fields(ctx)
          default_fields = self.ja_default_fields(ctx)
          fields = allowed_fields & default_fields
          if ctx[:fields].is_a?(Hash) && ctx[:fields][type].is_a?(Array)
            fields = ctx[:fields][type]
            fields = allowed_fields & fields
          end
          result[ctx] = fields
        end
        @ja_fields[context]
      end

      def ja_allowed_include(context = {})
        self.ja_direct_relationship_names
      end

      def ja_direct_relationships
        return @ja_direct_relationships if defined?(@ja_direct_relationships)
        @ja_direct_relationships = self.reflect_on_all_associations.map do |association|
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

      def ja_direct_relationship_names
        return @ja_direct_relationship_names if defined?(@ja_direct_relationship_names)
        @ja_direct_relationship_names = self.ja_direct_relationships.map{ |r| r[:name] }
      end

      # def ja_all_resource_klasses
      #   return @ja_all_resource_klasses if defined?(@ja_all_resource_klasses)
      #   res = []
      #   get_klasses = lambda do |res, klass|
      #     res << klass
      #     klass.reflect_on_all_associations.each do |association|
      #       next if association.options[:polymorphic]
      #       get_klasses.call(res, association.klass) unless res.include?(association.klass)
      #     end
      #   end
      #   get_klasses.call(res, self)
      #   @ja_all_resource_klasses = res
      # end

      def ja_included_resource_objects(objs, context = {})
        ctx = context.dup
        inc = ctx.delete(:include) || []
        included_resources_uids = [*objs].map(&:ja_resource_uid)
        build_included = lambda do |res, objs, path, options, included_resources_uids|
          options ||= {}
          included_resources_uids ||= []
          paths = path.split(".")
          [*objs].each do |obj|
            return unless obj.class.ja_allowed_include(context).include?(paths[0].to_sym)
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
        inc.inject([]) { |res, path| build_included.call(res, objs, path, ctx, included_resources_uids); res }
      end

      def ja_preload(context = {})
        @ja_preload ||= Hash.new do |result, ctx|
          ctx = ctx.dup
          self.ja_include_map!(ctx)
          inc = ctx[:include] || []
          inc = inc + ja_direct_relationships.select { |r| r[:type] == :belongs_to }.map { |r| r[:name].to_s }
          inc = inc.uniq
          build_preload = lambda do |klass, path|
            paths = path.split(".")
            return unless klass.ja_allowed_include(ctx).include?(paths[0].to_sym)
            if paths.size == 1
              paths[0].to_sym
            elsif paths.size > 1
              path = paths[1..-1].join(".")
              klass = klass.ja_direct_relationships.select { |r| r[:name].to_s == paths[0] }[0][:klass]
              return paths[0].to_sym unless klass.ja_allowed_include(ctx).include?(paths[1].to_sym)
              { paths[0].to_sym => build_preload.call(klass, path) }
            end
          end
          preload = inc.map { |path| build_preload.call(self, path) }.compact
          req_deep_merge = lambda do |a, b|
            a = { a => {} } unless a.is_a?(Hash)
            b = { b => {} } unless b.is_a?(Hash)
            a.deep_merge!(b) { |_, v1, v2| req_deep_merge.call(v1, v2) }
          end
          result[ctx] = preload.inject({}) { |h, v| req_deep_merge.call(h, v); h }
        end
        @ja_preload[context]
      end

      def ja_include_map!(context = {})
        @ja_include_map ||= Hash.new do |result, ctx|
          ctx = ctx.dup
          inc = ctx[:include] || []
          errors = {}
          populate_include_map = lambda do |res, obj, path|
            res ||= {}
            paths = path.split(".")
            return unless check_include_param!(ctx, errors, obj, paths[0])
            if paths.size == 1
              res[obj.class.ja_type] ||= []
              res[obj.class.ja_type] << paths[0].to_sym unless res[obj.class.ja_type].include?(paths[0].to_sym)
            elsif paths.size > 1
              populate_include_map.call(res, obj, paths[0])
              obj = obj.class.ja_direct_relationships.select { |r| r[:name].to_s == paths[0] }[0][:klass].new rescue nil
              path = paths[1..-1].join(".")
              populate_include_map.call(res, obj, path) if obj
            end
          end
          obj = self.new
          result[ctx] = inc.inject({}) { |res, path| populate_include_map.call(res, obj, path); res }

          # TODO: raise exception (if configured to do it)
          _debug "ERROR: #{errors}"
        end
        @ja_include_map[context]
      end

      def check_include_param!(context, errors = {}, obj, param)
        ok = true
        unless obj.respond_to?(param)
          er = "#{obj.class}##{param}"
          errors[:invalid_include_params] ||= []
          errors[:invalid_include_params] << er unless errors[:invalid_include_params].include?(er)
          ok = false
        end
        unless obj.class.ja_allowed_include(context).include?(param.to_sym)
          er = "#{obj.class}##{param}"
          errors[:restricted_include_params] ||= []
          errors[:restricted_include_params] << er unless errors[:restricted_include_params].include?(er)
          ok = false
        end
        ok
      end

    end

    def ja_resource_uid
      "#{self.class.ja_type}:#{self.send(self.class.ja_pk)}"
    end

    def ja_resource_identifier_object(context = {})
      res = {}
      res[:id] = self.send(self.class.ja_pk).to_s
      res[:type] = self.class.ja_type
      res
    end

    def ja_resource_object(context = {})
      res = ja_resource_identifier_object(context)
      res = ja_build_resource_object_attributes(res, context)
      res = ja_build_resource_object_relationships(res, context)
      res
    end

    def ja_error_objects(context = {})
      ctx = context.dup.reverse_merge!(pointer_path: "/data/attributes/")
      self.errors.as_json(full_messages: true).map do |field, errors|
        errors.map do |error|
          {
            detail: error,
            source: { pointer: "#{ctx[:pointer_path]}#{field}" }
          }
        end
      end.flatten
    end

  private

    def ja_build_resource_object_attributes(res, context = {})
      fields = self.class.ja_fields(context).dup
      fields.delete_if{ |m| !self.respond_to?(m) }
      methods = fields - self.class.attribute_names
      res[:attributes] = self.serializable_hash(only: fields, methods: methods).symbolize_keys
      res
    end

    def ja_build_resource_object_relationships(res, context = {})
      resource_types = self.class.ja_include_map!(context)[self.class.ja_type] || [] rescue []
      allowed_include = self.class.ja_allowed_include

      self.class.ja_direct_relationships.each do |relationship|
        next unless allowed_include.include?(relationship[:name])
        next if relationship[:type] != :belongs_to && !resource_types.include?(relationship[:name])
        if [:has_one, :belongs_to].include?(relationship[:type])
          res[:relationships] ||= {}
          res[:relationships][relationship[:name]] = {}
          res[:relationships][relationship[:name]][:data] = self.send(relationship[:name]).ja_resource_identifier_object(context) rescue nil
        elsif [:has_many, :has_and_belongs_to_many].include?(relationship[:type])
          res[:relationships] ||= {}
          res[:relationships][relationship[:name]] = {}
          res[:relationships][relationship[:name]][:data] = []
          self.send(relationship[:name]).each do |obj|
            res[:relationships][relationship[:name]][:data] << obj.ja_resource_identifier_object(context)
          end
        end
      end
      res
    end

  end
end
