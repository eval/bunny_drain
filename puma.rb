require './env'

workers ENVied.WORKERS if ENVied.respond_to?(:WORKERS)
threads ENVied.MIN_THREADS, ENVied.MAX_THREADS

#preload_app!

#rackup      DefaultRackup

port        ENVied.PORT
environment ENVied.RACK_ENV