require "spec"

require "./spec_helper"
require "../src/slack-events-api/challenge_handler"

def cspec
  SpecHandler.new SlackEvents::ChallengeHandler.new
end

good_challenge = JSON.build do |json|
  json.object do
    json.field "token", "doesntmatter"
    json.field "challenge", "challenge-string"
    json.field "type", "url_verification"
  end
end

wrong_type = JSON.build do |json|
  json.object do
    json.field "token", "doesntmatter"
    json.field "challenge", "challenge-string"
    json.field "type", "not_url_verification"
  end
end

wrong_schema = JSON.build do |json|
  json.object do
    json.field "name", "foo"
    json.field "values" do
      json.array do
        json.number 1
        json.number 2
        json.number 3
      end
    end
  end
end

describe SlackEvents::ChallengeHandler do
  describe "#call" do
    it "replies to the challenge with the challenge key" do
      request = simple_post(good_challenge)
      cspec.with request do |response|
        response.status_code.should eq 200
        response.headers["Content-Type"]?.should eq "text/plain"
        response.body.should eq "challenge-string"
      end
    end

    it "does nothing if challenge payload can't be parsed" do
      request = simple_post(":o")
      cspec.passthrough?(request).should be_true
    end

    it "does nothing if type is not a match " do
      request = simple_post(wrong_type)
      cspec.passthrough?(request).should be_true
    end

    it "does nothing if type is not a match " do
      request = simple_post(wrong_schema)
      cspec.passthrough?(request).should be_true
    end
  end
end
