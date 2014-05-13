require 'sinatra'
require 'bunny'
require 'connection_pool'
require 'envied'

class App < Sinatra::Base
  $amqp_conn = Bunny.new(ENVied.AMQP_URL).start
  $amqp_channel = ConnectionPool.new(size: ENVied.MAX_THREADS, timeout: 5) {
    $amqp_conn.create_channel
  }

  before do
    forbidden_on_unknown_drain_token!
  end

  # Logplex headers:
  # HTTP_LOGPLEX_MSG_COUNT"=>"2",
  # HTTP_LOGPLEX_FRAME_ID"=>""
  # HTTP_LOGPLEX_DRAIN_TOKEN"=>"",
  # HTTP_USER_AGENT"=>"Logplex/v72"
  post '/' do
    request.body.rewind

    $amqp_channel.with do |ch|
      request.body.each do |line|
        log = line.split(/>\d* /).last.to_s.strip
        puts "Publishing #{log[0...12].inspect} to exchange #{exchange_name.inspect} with routing key: #{routing_key.inspect}"
        ch.topic(exchange_name).publish(log, routing_key: routing_key)
      end
    end

    status 201
  end

  helpers do
    def exchange_name
      ENVied.AMQP_EXCHANGE % { drain_name: drain_name, drain_token: drain_token }
    end

    def routing_key
      ENVied.AMQP_ROUTING_KEY % { drain_name: drain_name, drain_token: drain_token }
    end

    # Drain-tokens mapped to drain-names.
    #
    # @note drains that you haven't assigned a name in DRAIN_NAME_MAPPING, will
    # have the drain-token as name. See example below.
    #
    # @example
    #   # Given the following mapping:
    #   ENV['DRAIN_NAME_MAPPING'] = 'drain-token1=name1&drain-token2='
    #   drain_name_mapping
    #   # => {'drain-token1' => 'name1', 'drain-token2' => 'drain-token2'}
    #
    # @return [<Hash{String => String}>] the mapping
    def drain_name_mapping
      @drain_name_mapping ||= begin
        ENVied.DRAIN_NAME_MAPPING.inject({}) do |res, (token, name)|
          res[token] = (name.empty? ? token : name)
          res
        end
      end
    end

    def drain_token
      env["HTTP_LOGPLEX_DRAIN_TOKEN"]
    end

    def drain_name
      drain_name_mapping[drain_token]
    end

    def known_drain_token?
      drain_name_mapping.has_key?(drain_token)
    end
  end

  def forbidden_on_unknown_drain_token!
    unless known_drain_token?
      halt 403
    end
  end
end
