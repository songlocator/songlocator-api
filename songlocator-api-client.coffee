###

  songlocator-base

  2013 (c) Andrey Popp <8mayday@gmail.com>

###
((root, factory) ->
  if typeof exports == 'object'
    SongLocator = require 'songlocator-base'
    module.exports = factory(SongLocator)
  else if typeof define == 'function' and define.amd
    define (require) ->
      SongLocator = require 'songlocator-base'
      root.SongLocator.API = factory(SongLocator)
  else
    root.SongLocator.API = factory(window.SongLocator)

) this, ({BaseResolver, extend}) ->

  class Client extends BaseResolver

    constructor: (options) ->
      this.options = options
      this.queue = []
      this.initSocket()

    initSocket: ->
      this.isOpenned = false
      this.sock = new WebSocket(this.options.uri)
      this.sock.onopen = =>
        this.isOpenned = true
        if this.queue.length > 0
          for {method, data} in this.queue
            this.call(method, data)
          this.queue = []
      this.sock.onerror = => this.initSocket()
      this.sock.onmessage = this.onMessage.bind(this)

    onMessage: (e) ->
      data = try
        JSON.parse e.data
      catch e
        undefined # TODO: logging
      return unless data?.qid? and data?.results?
      this.results(data.qid, data.results)

    call: (method, data) ->
      if this.isOpenned
        data.method = method
        this.sock.send JSON.stringify data
      else
        this.queue.push {method, data}

    search: (qid, query) ->
      this.call 'search', {qid, query}

    resolve: (qid, title, artist, album) ->
      this.call 'resolve', {qid, title, artist, album}

  {Client}
