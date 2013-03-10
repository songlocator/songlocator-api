{Server} = require 'ws'
{v4} = require 'node-uuid'

{ResolverSet} = require 'songlocator-base'
{readConfigSync, parseArguments} = require 'songlocator-cli'

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

    resolvers = for name, cfg of config
      resolverCls = (require("songlocator-#{name}")).Resolver
      new resolverCls(cfg)

    resolver = new ResolverSet(resolvers)
    resolver.on 'results', send

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
        resolver.search(qid, req.query)

      else if req.method == 'resolve'
        resolver.search(qid, req.title, req.artist, req.album)

  console.log "start listening on localhost:#{port}"
  server
