require_relative '../../lib/active_controller/active_controller'

class ApplicationController < ActiveController
  protect_from_forgery
end
