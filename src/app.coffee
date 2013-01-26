express = require 'express'
{ResolverSet} = require './resolver'

createApp = (config) ->

  app = express()

  app.resolver = ResolverSet.fromConfig(config.resolvers)

  app.get '/search', (req, res) ->
    res.send 'searched'

  app.get '/resolve', (req, res) ->
    res.send 'resolved'

  app

main = (port = 3000) ->
  app = createApp
    resolvers:
      soundcloud: {}
  app.listen 3000

  resolversNames = for r in app.resolver.resolvers
    r.settings.name

  console.log "Start listening on localhost:#{port}"
  console.log "with the following resolvers: #{resolversNames.join(', ')}"

  app

module.exports = {createApp, main}
