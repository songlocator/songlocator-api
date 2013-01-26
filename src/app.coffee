{Server} = require 'ws'
{v4} = require 'node-uuid'

{ResolverSet} = require './resolverset'

exports.main = (port = 3000) ->
  server = new Server(port: port)

  server.on 'connection', (sock) ->
    resolver = ResolverSet.fromConfig
      soundcloud: {}
      youtube: {}
      exfm: {}

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
