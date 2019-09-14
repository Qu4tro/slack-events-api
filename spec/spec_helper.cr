class SpecHandler
  def initialize(@handler : HTTP::Handler)
  end

  def handler
    @handler
  end

  def with(request, &block)
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    @handler.call(context)
    response.close

    io.rewind
    yield HTTP::Client::Response.from_io(io)
  end

  def make_request(request)
    self.with request do |r|
    end
  end

  def passthrough?(request)
    not_found? request
  end

  def not_found?(request)
    self.with request do |response|
      not_found = response.status_code == 404
      not_found &&= response.headers["Content-Type"]? == "text/plain"
      not_found &&= response.body == "Not Found\n"
      not_found
    end
  end

  def forbidden?(request, message = nil)
    self.with request do |response|
      return response.status_code == 403
    end
  end
end

def simple_post(body, headers = nil)
  HTTP::Request.new("POST", "/", headers, body)
end
