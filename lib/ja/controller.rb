require "active_support/concern"
require "ja/controller/utils/resource"
require "ja/controller/utils/render"
require "ja/controller/before_actions/content_negotiation"
require "ja/controller/before_actions/fields"
require "ja/controller/before_actions/filters"
require "ja/controller/before_actions/includes"
require "ja/controller/before_actions/sort"
require "ja/controller/before_actions/pagination"
require "ja/controller/before_actions/links"
require "ja/controller/actions/resources"
require "ja/controller/actions/relationships"

module Ja
  module Controller
    extend ActiveSupport::Concern

    class_methods do
      def ja! options={}
        include Ja::Controller::Utils::Resource
        include Ja::Controller::Utils::Render

        include Ja::Controller::BeforeActions::ContentNegotiation
        include Ja::Controller::BeforeActions::Fields
        include Ja::Controller::BeforeActions::Filters
        include Ja::Controller::BeforeActions::Includes
        include Ja::Controller::BeforeActions::Sort
        include Ja::Controller::BeforeActions::Pagination
        include Ja::Controller::BeforeActions::Links

        include Ja::Controller::Actions::Resources
        include Ja::Controller::Actions::Relationships
      end
    end

  end
end
