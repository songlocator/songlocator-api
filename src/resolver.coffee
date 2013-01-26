###

  Utilities for working with Playdar resolvers.

###

{EventEmitter} = require 'events'
request = require 'request'
url = require 'url'
{extend} = require 'underscore'

###
  Base class for resolvers.
###
class exports.BaseResolver extends EventEmitter

  constructor: (settings) ->
    this.settings = extend({}, this.settings or {}, settings)

  resolve: (qid, artist, title) ->
    {qid}

  search: (qid, searchString) ->
    this.resolve(qid, '', '', searchString)

  request: (uri, params, callback) ->
    params = url.format(query: params)
    uri = "#{uri}#{params}"
    request(uri, callback)

  log: (msg, debug = false) ->
    return if debug and not this.settings.debugMode
    console.log "#{this.settings.name}: #{msg}"

  result: (m) ->
    this.emit('result', m)

  end: (m) ->
    this.emit('end', m)

###
  Facade for working with a set of resolvers.
###
class exports.ResolverSet extends EventEmitter

  @fromConfig: (config) ->
    resolvers = for resolverName, resolverConfig of config
      {Resolver} = require "./resolvers/#{resolverName}"
      new Resolver(resolverConfig)

    new this(resolvers)

  constructor: (resolvers) ->
    this.resolvers = resolvers

    for r in this.resolvers
      r.on 'result', (args...) =>
        this.emit('result', args...)
      r.on 'end', (args...) =>
        this.emit('end', args...)

  search: (qid, searchString) ->
    for r in this.resolvers
      r.search(qid, searchString)

  resolve: (qid, artist, title) ->
    for r in this.resolvers
      r.resolve(qid, artist, title)
