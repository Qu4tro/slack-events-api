require "openssl/hmac"
require "http/server"
require "http/server/handler"

# Slack signs its requests using a secret that's unique to your app.
# With the help of signing secrets,
# your app can more confidently verify whether requests from us are authentic.
module SlackEvents
  # Middleware that verifies that requests are correctly signed with `SLACK_SIGNING_SECRET` by Slack.
  class VerificationHandler
    include HTTP::Handler

    # Initialize with the unique string Slack creates for your app.
    # Verify requests from Slack with confidence by verifying signatures
    # using your signing secret.
    def initialize(@signing_secret : String)
    end

    # Requests that go through this middleware need to have a valid signature
    # or are a '403 - Forbidden' will be returned to the client.
    def call(context)
      return forbidden context unless valid? context.request

      call_next(context)
    end

    # Mutate the response status to '403 - Forbidden'.
    protected def forbidden(context)
      context.response.status_code = 403
    end

    # Check for all necessary conditions for a request to be a valid event.
    protected def valid?(request)
      request.method == "POST" &&
        (valid_age? request) &&
        (valid_signature? request)
    end

    # Compare this computed signature to the X-Slack-Signature header on the request.
    def valid_signature?(request)
      (computed_signature request) == request.headers["X-Slack-Signature"]?
    end

    # The signature depends on the timestamp to protect against replay attacks.
    # Check to make sure that the request occurred recently.
    # NOTE: The package defaults to accepting timestamps that
    # are within 5 minutes of the current time.
    # i.e. It can be either from 3 minutes ago or 3 minutes from now.
    def valid_age?(request)
      req_ts = Time.unix (timestamp request.headers).to_i
      now_ts = Time.utc_now

      age = now_ts - req_ts

      age.duration < Time::Span.new(hours: 0, minutes: 5, seconds: 0)
    end

    # With the help of HMAC SHA256 - `OpenSSL::HMAC` hash the basestring,
    # using the Slack Signing Secret - `@signing_secret` - as the key.
    def computed_signature(request)
      "v0=" + OpenSSL::HMAC.hexdigest(:sha256, @signing_secret, basestring request)
    end

    # Concatenate the version number, the timestamp,
    # and the body of the request to form a basestring.
    # Use a colon as the delimiter between the three elements.
    # For example, v0:123456789:command=/weather&text=94070.
    protected def basestring(request)
      [
        version_number,
        timestamp(request.headers),
        body(request),
      ].join(":")
    end

    # The version number right now is always v0.
    protected def version_number
      "v0"
    end

    # Retrieves the X-Slack-Request-Timestamp header
    # If it's missing it defaults to to 0 - i.e. 01Jan, 1970 and therefore is never valid.
    protected def timestamp(headers)
      headers["X-Slack-Request-Timestamp"] || "0"
    end

    # Peek into the body and return it as a string
    # We use `IO.peek` so that middlewares down the line can read from it.
    protected def body(request)
      String.new(request.body.not_nil!.peek.not_nil!)
    end
  end
end
