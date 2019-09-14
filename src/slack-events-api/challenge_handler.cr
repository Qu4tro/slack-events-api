require "json"
require "http/server"
require "http/server/handler"

# Verifies ownership of an Events API Request URL
# This event does not require a specific OAuth scope or subscription.
# You'll automatically receive it whenever configuring an Events API URL.
module SlackEvents
  # Only used for deserializing the payload sent by Slack
  private class Challenge
    # JSON mapping for the challenge payload
    JSON.mapping(
      token: String,
      challenge: String,
      type: String,
    )
  end

  # Middleware that does the initial challenge handshake with Slack.
  # It always need to be used with and after `SlackEvents::VerificationHandler`.
  class ChallengeHandler
    include HTTP::Handler

    # Requests that go through this middleware either:
    # Are challenges - and the correct response is returned
    # Are some other event - and the middleware does nothing
    def call(context)
      challenge = get_challenge context.request
      return call_next(context) if challenge == nil

      context.response.status_code = 200
      context.response.content_type = "text/plain"
      context.response.print challenge
    end

    # Parse and validate a challenge payload.
    # It's used to identify whetever it's a challenge.
    protected def get_challenge(request)
      object = Challenge.from_json(request.body.not_nil!)
      return nil if object.type != "url_verification"

      object.challenge
    rescue JSON::ParseException
      nil
    end
  end
end
