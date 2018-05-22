require 'rack'
require_relative '../lib/active_controller/router'
require_relative '../lib/active_model/db_connection'

router = Router.new
router.draw do
  # INCLUDE ROUTES HERE!

  # e.g. get Regexp.new("^/dogs$"), DogsController, :index
  # e.g. get Regexp.new("^/dogs/(?<id>\\d+)$"), DogsController, :show
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

Rack::Server.start(
 app: app,
 Port: 3000
)
