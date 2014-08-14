# Bunny Drain

## What is it?

Bunny drain will get your heroku logs to RabbitMQ.

## Quickstart

### Prerequisites:
* Ruby version >= 1.9.3
* RabbitMQ running on `127.0.0.1:5672`
* a Heroku-app
* a publicly accessible url that will forward traffic to your local machine

### Install:
```bash
git clone https://github.com/eval/bunny_drain.git
cd bunny_drain
bundle install --binstubs
```

### Boot:
```bash
export RACK_ENV=development
bin/foreman start web
# open http://localhost:5000 to verify the server is running
```
Without input not a lot will happen. So let's...
### Connect a drain:

Besides a heroku-app, we need a publicly accessible url that will forward traffic to our local server.
Install for example [localtunnel.me](http://localtunnel.me/), and generate a url:
```bash
lt --port 5000
your url is: https://gqgh.localtunnel.me
```
We now add this url as a syslog-drain to our Heroku-app:
```bash
heroku drains:add https://gqgh.localtunnel.me --app my-heroku-app
# Get the drain-token:
heroku drains
# https://gqgh.localtunnel.me (d.xxxxxxxx-yyyy-zzzz-xxxx-yyyyyyyyyyyy)

# Bunny Drain will only accept POSTs with certain drain-tokens. 
# Let's make it available to the server:
export DRAIN_NAME_MAPPING="d.xxxxxxxx-yyyy-zzzz-xxxx-yyyyyyyyyyyy=my-heroku-app"
# restart the server, visit your heroku-app and see the logs come in!
```

## Configuration

See [Envfile](Envfile) for all ENV-variables that will help you configure the server.

Note: when running the server with `RACK_ENV=production` all these ENV-variables should be provided.

## Development

To make changes to the application without restarting, the app uses [Shotgun](https://github.com/rtomayko/shotgun).  
Just start foreman using `Procfile.dev`:

```bash
bin/foreman start web -f Procfile.dev
```

## License

Released under the MIT license.
