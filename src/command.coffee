{isArray} = require 'util'
{v4} = require 'node-uuid'

{readConfigSync, parseArguments, extend} = require './utils'
{ResolverSet} = require './resolverset'

getResolver = (config, resolverNames = []) ->
  config = extend({}, config)

  for resolverName in resolverNames
    config[resolverName] = {}

  resolver = ResolverSet.fromConfig(config)
  resolver.on 'result', (r) ->
    r.results.forEach (t) ->
      console.log "#{t.artist} — #{t.track}"
  resolver

exports.search = ->
  {args: [searchString], opts} = parseArguments()

  if not searchString?
    throw new Error('provide search term as arg') 

  config = readConfigSync(opts.config) or {}
  getResolver(config, opts.resolvers).search(v4(), searchString)

exports.resolve = ->
  {args: [artist, track, album], opts} = parseArguments()

  if not artist? and track?
    throw new Error('provide artist and track as first two args') 

  config = readConfigSync(opts.config) or {}

  getResolver(config, opts.resolvers).resolve(v4(), artist, album or '', track)
