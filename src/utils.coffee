{readFileSync} = require 'fs'

exports.readConfigSync = (filename = './songlocator.json') ->
  try
    JSON.parse readFileSync(filename)
  catch e
    undefined
