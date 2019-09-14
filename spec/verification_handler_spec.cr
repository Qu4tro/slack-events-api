require "spec"

require "./spec_helper"
require "../src/slack-events-api/verification_handler"

def vspec
  SpecHandler.new SlackEvents::VerificationHandler.new("secret")
end

def signed_post(timestamp = Time.utc.to_unix.to_s, signature = nil)
  headers = HTTP::Headers{
    "X-Slack-Signature"         => signature || "",
    "X-Slack-Request-Timestamp" => timestamp,
  }

  request = simple_post("doesntmatter", headers: headers)

  if signature == nil
    request.headers["X-Slack-Signature"] =
      vspec.handler
        .as(SlackEvents::VerificationHandler)
        .computed_signature(request)
  end

  request
end

describe SlackEvents::VerificationHandler do
  describe "passing #call" do
    it "allows the request through if the signature is correct" do
      vspec.passthrough?(signed_post).should be_true
    end

    it "gives the request some leeway if the signature is outdated" do
      past = Time.utc_now - Time::Span.new(hours: 0, minutes: 4, seconds: 0)
      past_ts = past.to_unix.to_s
      vspec.forbidden?(signed_post timestamp: past_ts).should be_false
    end

    it "gives the request some leeway if the signature is from the future" do
      future = Time.utc_now + Time::Span.new(hours: 0, minutes: 4, seconds: 0)
      future_ts = future.to_unix.to_s
      vspec.forbidden?(signed_post timestamp: future_ts).should be_false
    end
  end

  describe "blocing #call" do
    it "blocks the request if the signature is outdated" do
      past = Time.utc_now - Time::Span.new(hours: 0, minutes: 10, seconds: 0)
      past_ts = past.to_unix.to_s
      vspec.forbidden?(signed_post timestamp: past_ts).should be_true
    end

    it "blocks the request if the signature is from the future" do
      future = Time.utc_now + Time::Span.new(hours: 0, minutes: 10, seconds: 0)
      future_ts = future.to_unix.to_s
      vspec.forbidden?(signed_post timestamp: future_ts).should be_true
    end

    it "blocks the request if the signature is wrong" do
      request1 = signed_post signature: ":o"
      request2 = signed_post signature: "itsme"
      request3 = signed_post signature: "letmein"
      request4 = signed_post signature: "iforgotthesecretknock"

      vspec.forbidden?(request1).should be_true
      vspec.forbidden?(request2).should be_true
      vspec.forbidden?(request3).should be_true
      vspec.forbidden?(request4).should be_true
    end
  end

  describe "#computed_signature" do
    it "computes a signture correctly" do
      signature = "v0=3de8edba6fa2f065b575537fba33bd4c4217aa3d649c7852dd831e2b8caff0ad"
      request = signed_post(signature: signature, timestamp: "1234567890")

      vspec.handler
        .as(SlackEvents::VerificationHandler)
        .computed_signature(request)
        .should eq signature
    end
  end
end
