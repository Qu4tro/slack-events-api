# Slack Events API adapter for Crystal

[![Build Status](https://travis-ci.com/Qu4tro/slack-events-api.svg?token=Mqsa3fKeSUryp43kNdBt&branch=master)](https://travis-ci.com/Qu4tro/slack-events-api)

[![Github release](https://img.shields.io/github/release/qu4tro/slack-events-api.svg)](https://github.com/qu4tro/slack-events-api/releases)

### The middlewares you need to deal with Slack Events API

## Overview

slack-events-api is a [Crystal](https://crystal-lang.org/) package composed of two middlewares:

`SlackEvents::VerificationHandler`
  - Middleware that verifies that requests are correctly signed with `SLACK_SIGNING_SECRET` by Slack. All requests going through this middleware, will be checked. In the event of a request whose signature couldn't be verified, the middleware will early return with a `403 - Forbidden`.
  - Receives `SLACK_SIGNING_SECRET` as its sole argument.


`SlackEvents::ChallengeHandler`
  - Middleware that does the initial challenge handshake between Slack and your API.
  
Further documentation can be found in https://qu4tro.github.io/slack-events-api/

## Installation

1. Add this to your application's `shard.yml`:

```yaml
dependencies:
  slack-events-api:
    github: qu4tro/slack-events-api
```
2. Run `shards install`


## Usage
This example will suffice to perform the initial setup, but actual events will be 404'd, until you write your application-specific handler.

```crystal
#!/usr/bin/env crystal

require "http/server"
require "http/server/handler"

require "slack-events-api"

middlewares = [
  HTTP::LogHandler.new.as(HTTP::Handler),
  HTTP::ErrorHandler.new,
  SlackEvents::VerificationHandler.new(ENV["SLACK_SIGNING_SECRET"]),
  SlackEvents::ChallengeHandler.new,
] 

HTTP::Server.new(middlewares).tap do |server|
  address = server.bind_tcp "localhost", ENV["PORT"].to_i
  puts "Listening on http://#{address}"
  server.listen
end
```
## Further work

- Make JSON mappings for all event types supported by the Event API 
- If a reverse-proxy middleware comes up for Crystal, I think it's worth thinking about creating a docker image, to allow for the verification and challenge-setup to be automated for any ad-hoc server.


## Development

Any restriction to development should be tool-automated.
So, feel free to open PRs. If all the tests pass, it should be good to merge, if it fits the package domain - opening an issue is a good way to clarify. In fact, feel free to open issues for any type of clarification.


## Contributing

1. [Fork it](https://github.com/Qu4tro/slack-events-api/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## Authors

* **Xavier Francisco** - *Initial work* - [Qu4tro](https://github.com/Qu4tro)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
