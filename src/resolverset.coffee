###

  Utilities for working with Playdar resolvers.

###

{EventEmitter} = require 'events'

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

  search: (qid, searchString) ->
    for r in this.resolvers
      r.search(qid, searchString)

  resolve: (qid, artist, album, title) ->
    for r in this.resolvers
      r.resolve(qid, artist, album, title)
