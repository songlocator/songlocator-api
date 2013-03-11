{Server} = require 'ws'
{v4} = require 'node-uuid'

{ResolverSet} = require 'songlocator-base'
{readConfigSync, parseArguments} = require 'songlocator-cli'

class exports.SongLocatorServer
  constructor: (config) ->
    this.config = config
    this.server = undefined

  log: (args...) ->
    console.log(args...)

  debug: (args...) ->
    this.log(args...) if this.config.debug?

  serve: ->
    this.server = new Server(port: this.config.port or 3000)

    this.server.on 'connection', (sock) =>

      this.debug('got new connection')

      send = (msg) =>
        this.debug('response', {qid: msg.qid, length: msg.results.length}) 
        sock.send JSON.stringify msg

      resolvers = for name, cfg of this.config.resolvers
        resolverCls = (require("songlocator-#{name}")).Resolver
        new resolverCls(cfg)

      resolver = new ResolverSet(resolvers)

      resolver.on 'results', send

      sock.on 'message', (message) =>

        req = try
          JSON.parse(message)
        catch e
          undefined

        return unless req

        # generate qid if no qid was supplied
        qid = req.qid or v4()

        this.debug('request', req) 

        if req.method == 'search'
          resolver.search(qid, req.query)

        else if req.method == 'resolve'
          resolver.search(qid, req.title, req.artist, req.album)

    this.log "start listening on localhost:#{this.config.port}"

exports.main = (port = 3000) ->
  {opts} = parseArguments()

  config = readConfigSync(opts.config) or {}
  for resolverName in opts.resolvers
    config[resolverName] = {}

  server = new exports.SongLocatorServer
    debug: opts.debug
    port: port
    resolvers: config

  server.serve()
