
module Ja
  module Routing

    def ja_resources(*res, &block)
      res.each do |r|

        # hack - redefine parent param name
        if parent_resource
          parent_resource_param = parent_resource.param
          parent_resource.define_singleton_method(:nested_param) do
            parent_resource_param
          end
        end

        options = res.extract_options!
        options.merge! param: "#{r.to_s.singularize}_pk"

        resources r, options do
          yield if block_given?
        end
      end
    end

  end
end
