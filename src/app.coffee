{parse} = require 'argsparser'
{Server} = require 'ws'
{v4} = require 'node-uuid'

{readConfigSync} = require './utils'
{ResolverSet} = require './resolverset'

exports.main = (port = 3000) ->
  opts = parse()
  config = readConfigSync(opts['-c']) or {youtube: {}}
  server = new Server(port: port)

  server.on 'connection', (sock) ->
    resolver = ResolverSet.fromConfig(config)

    resolver.on 'result', (result) ->
      sock.send JSON.stringify result

    sock.on 'message', (message) ->
      req = JSON.parse(req)
      qid = req.qid or v4()
      if req.method == 'search'
        resolver.search(qid, req.searchString)
      else if req.method == 'resolve'
        resolver.search(qid, req.artist, req.album, req.track)

  console.log "Start listening on localhost:#{port}"
  server
