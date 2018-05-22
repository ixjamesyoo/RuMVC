require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'

class ActiveController
  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = route_params.merge(req.params)
    @already_built_response = false
    @@protect_from_forgery ||= false
  end

  def redirect_to(url)
    raise "Double Render Error FOOL" if already_built_response?
    @res.location = url
    @res.status = 302
    session.store_session(@res)
    flash.store_flash(@res)
    @already_built_response = true
  end

  def render_content(content, content_type)
    raise "Double Render Error FOOL" if already_built_response?
    @res.write(content)
    @res["Content-Type"] = content_type
    session.store_session(@res)
    flash.store_flash(@res)
    @already_built_response = true
  end

  def render(template_name)
    dir_path = File.dirname(__FILE__)
    template_fname = File.join(
      dir_path, "..",
      "views", self.class.name.underscore, "#{template_name}.html.erb"
    )

    template_code = File.read(template_fname)

    render_content(
      ERB.new(template_code).result(binding),
      "text/html"
    )
  end

  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  def invoke_action(name)
    protect_from_forgery? && req.request_method != "GET" ?
      check_authenticity_token :
      form_authenticity_token

    self.send(name)
    render(name) unless already_built_response?
  end

  protected
  def self.protect_from_forgery
    @@protect_from_forgery = true
  end

  private
  def already_built_response?
    !!@already_built_response
  end

  def protect_from_forgery?
    @@protect_from_forgery
  end

  def form_authenticity_token
    @token ||= generate_authenticity_token
    res.set_cookie('authenticity_token', value: @token, path: '/')
    @token
  end

  def check_authenticity_token
    cookie = @req.cookies["authenticity_token"]
    unless cookie && cookie == params["authenticity_token"]
      raise "Invalid authenticity token"
    end
  end

  def generate_authenticity_token
    SecureRandom.urlsafe_base64(16)
  end
end
