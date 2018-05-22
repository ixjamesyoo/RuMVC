require 'json'

class Session
  def initialize(req)
    cookie = req.cookies["_rails_lite_app"]
    if cookie
      @data = JSON.parse(cookie)
    else
      @data = {}
    end
  end

  def [](key)
    @data[key.to_s]
  end

  def []=(key, val)
    @data[key.to_s] = val
  end

  def store_session(res)
    val = @data.to_json
    res.set_cookie("_rails_lite_app", path: "/",  value: val)
  end
end
