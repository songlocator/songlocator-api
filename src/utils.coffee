{readFileSync} = require 'fs'

exports.readConfigSync = (filename = './songlocator.json') ->
  try
    JSON.parse readFileSync(filename)
  catch e
    undefined

exports.extend = (t, os...) ->
  for o in os
    for k, v of o
      t[k] = v
  t
