{parse} = require 'argsparser'
{isArray} = require 'util'
{v4} = require 'node-uuid'

{readConfigSync} = require './utils'
{ResolverSet} = require './resolverset'

getResolver = (config) ->
  resolver = ResolverSet.fromConfig(config)
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

  config = readConfigSync(opts['-c']) or {youtube: {}}

  getResolver(config).search(v4(), searchString)
