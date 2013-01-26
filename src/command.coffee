{ResolverSet} = require './resolver'
{parse} = require 'argsparser'
{isArray, uniqueId} = require 'underscore'

exports.search = ->
  resolver = ResolverSet.fromConfig
    soundcloud: {}
  resolver.on 'result', (r) ->
    r.results.forEach (t) ->
      console.log "#{t.artist} — #{t.track}"

  opts = parse()
  searchString = if isArray(opts.node) and opts.node.length > 0
    opts.node[1]
  else
    throw new Error('provide search term as arg')

  resolver.search uniqueId('search'), searchString
