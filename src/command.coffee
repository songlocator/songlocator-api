{ResolverSet} = require './resolver'
{parse} = require 'argsparser'
{isArray, uniqueId} = require 'underscore'

getResolver = ->
  resolver = ResolverSet.fromConfig
    soundcloud: {}
    exfm: {}
  resolver.on 'result', (r) ->
    r.results.forEach (t) ->
      console.log "#{t.artist} — #{t.track}"
  resolver

exports.search = ->
  opts = parse()
  searchString = if isArray(opts.node) and opts.node.length > 0
    opts.node[1]
  else
    throw new Error('provide search term as arg')

  getResolver().search uniqueId('search'), searchString
