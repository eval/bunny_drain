require 'sinatra'
require 'bunny'
require 'connection_pool'
require 'envied'

class App < Sinatra::Base
  $amqp_conn = Bunny.new(ENVied.AMQP_URL).start
  $amqp_channel = ConnectionPool.new(size: ENVied.MAX_THREADS, timeout: 5) {
    $amqp_conn.create_channel
  }

=begin
Logplex headers:
"HTTP_LOGPLEX_MSG_COUNT"=>"2",
"HTTP_LOGPLEX_FRAME_ID"=>""
"HTTP_LOGPLEX_DRAIN_TOKEN"=>"",
"HTTP_USER_AGENT"=>"Logplex/v72"
=end

  post '/' do
    request.body.rewind
    body = request.body.readlines
    drain_token = env["HTTP_LOGPLEX_DRAIN_TOKEN"]

    $amqp_channel.with do |ch|
      body.each do |line|
        log = line.split(/>\d* /).last.to_s.strip
        ch.topic("bunny-drain").publish(log, routing_key: "heroku.logs.#{drain_token}")
      end
    end
  end
end
