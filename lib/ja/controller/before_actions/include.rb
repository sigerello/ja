require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Include
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_include
        end

      private

        def ja_include
          ja_resource_class.ja_include
        end

        def ja_restricted_include
          ja_resource_class.ja_restricted_include
        end

        def ja_set_include
          inc = params[:include].split(",") rescue nil
          inc = ja_include if inc.nil?
          inc = inc.map(&:to_s) - ja_restricted_include.map(&:to_s)
          inc.each { |path| ja_resource_class.ja_check_include!(ja_resource_class.new, path) }
          @ja_include = inc
        end

      end
    end
  end
end
