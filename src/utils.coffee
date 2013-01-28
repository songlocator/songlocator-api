{readFileSync} = require 'fs'

exports.readConfigSync = (filename = './songlocator.json') ->
  try
    JSON.parse readFileSync(filename)
  catch e
    undefined

exports.parseArguments = (argv = process.argv) ->
  argv = argv.splice(2)
  args = []
  opts = {config: undefined, resolvers: []}
  while argv.length > 0
    arg = argv.shift()

    if arg == '-c' or args == '--config'
      opts.config = argv.shift()

    else if arg == '--debug'
      opts.debug = true

    else if arg.substring(0, 6) == '--use-'
      opts.resolvers.push(arg.substring(6))

    else
      args.push(arg)

  {args, opts}

exports.extend = (t, os...) ->
  for o in os
    for k, v of o
      t[k] = v
  t
