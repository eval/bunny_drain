require 'envied'

ENVied.configure(enable_defaults: ENV['RACK_ENV'] != 'production') do
  variable :RACK_ENV
  variable :PORT, :Integer, default: 5000
  variable :MIN_THREADS, :Integer, default: 1
  variable :MAX_THREADS, :Integer, default: 10
  variable :AMQP_URL, :String, default: 'amqp://127.0.0.1:5672'

  group :production do
    variable :WORKERS, :Integer
  end
end

ENVied.require(:default, ENV['RACK_ENV'])
