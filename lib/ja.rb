require "ja/version"
require "ja/controller"
require "ja/model"

require "action_controller"
require "active_record"

ActionController::Metal.send :include, Ja::Controller
ActiveRecord::Base.send :include, Ja::Model
