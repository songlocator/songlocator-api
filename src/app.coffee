{Server} = require 'ws'
{v4} = require 'node-uuid'

{readConfigSync, parseArguments} = require './utils'
{ResolverSet} = require './resolverset'

exports.main = (port = 3000) ->
  {opts} = parseArguments()

  config = readConfigSync(opts.config) or {}
  for resolverName in opts.resolvers
    config[resolverName] = {}

  server = new Server(port: port)

  server.on 'connection', (sock) ->
    if opts.debug
      console.log('got new connection')

    send = (msg) ->
      if opts.debug
        console.log('response', {qid: msg.qid, length: msg.results.length}) 
      sock.send JSON.stringify msg

    resolver = ResolverSet.fromConfig(config)

    resolver.on 'result', send

    sock.on 'message', (message) ->
      req = try
        JSON.parse(message)
      catch e
        undefined

      return unless req

      # generate qid if no qid was supplied
      qid = req.qid or v4()

      if opts.debug
        console.log('request', req) 

      if req.method == 'search'
        resolver.search(qid, req.searchString)

      else if req.method == 'resolve'
        resolver.search(qid, req.artist, req.album, req.track)

  console.log "start listening on localhost:#{port}"
  server
