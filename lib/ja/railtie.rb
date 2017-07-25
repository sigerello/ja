require "rails"
require "ja/controller/utils/exception_handler"
require "ja/routing"
require "ja/controller"
require "ja/model"

module Ja
  class Railtie < Rails::Railtie
    config.ja = ActiveSupport::OrderedOptions.new

    # Set to false in config/application.rb file to disable error handling
    config.ja.error_handling = true

    initializer "ja.error_handling" do |app|
      if config.ja.error_handling
        app.config.consider_all_requests_local = false
        app.config.action_dispatch.show_exceptions = true
        app.config.exceptions_app = -> (env) { ActionController::API.action(:ja_render_exception).call(env) }

        # Rethrow exceptions with around_action because we can't rethrow
        # them in rescue handlers
        Ja::Controller::Utils::ExceptionHandler.included do
          around_action :ja_rethrow_exception
          rescue_from StandardError, with: :ja_render_exception
        end

        # Redefine to allow handling of ActionController::RoutingError
        # in upper middleware ActionDispatch::ShowExceptions
        class ActionDispatch::DebugExceptions
          def render_exception(request, exception)
            raise exception
          end
        end

        # Define explicitly because methods from included modules
        # are not considered as actions
        class ActionController::API
          def ja_render_exception exception=nil
            super
          end
        end

        # Replace default html FAILSAFE_RESPONSE with json one
        ActionDispatch::ShowExceptions::FAILSAFE_RESPONSE.replace [500, { "Content-Type" => "application/json" }, ['{"errors":[{"status":500,"title":"Internal Server Error"}]}']]
      end
    end

    initializer "ja.include_mixins" do |app|
      ActionDispatch::Routing::Mapper.send :include, Ja::Routing

      # Include to both ActionController::API and ActionController::Base classes
      # because we don't know which one user will use as base class for his controllers
      ActiveSupport.on_load(:action_controller) do
        ActionController::API.send :include, Ja::Controller
        ActionController::API.send :include, Ja::Controller::Utils::ExceptionHandler

        ActionController::Base.send :include, Ja::Controller
        ActionController::Base.send :include, Ja::Controller::Utils::ExceptionHandler
      end

      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, Ja::Model
      end
    end

  end
end