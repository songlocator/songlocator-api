###
  Shim which allows to re-use tomahawk resolvers almost "as-is".
###

{XMLHttpRequest} = require 'xmlhttprequest'
{EventEmitter} = require 'events'

{extend} = require './utils'

exports.window = {}

exports.Tomahawk =

  resolver: {}

  readBase64: ->
    undefined

  extend: (base, obj) ->
    class AdaptedResolver extends EventEmitter
      constructor: (settings = {}) ->
        this.init()
        this.settings = extend({}, (this.settings or {}), settings)
    extend(AdaptedResolver.prototype, base, obj)
    AdaptedResolver

  log: (message) ->
    #console.log message

  asyncRequest: (url, callback, extraHeaders) ->
    xmlHttpRequest = new XMLHttpRequest()
    xmlHttpRequest.open('GET', url, true)
    if extraHeaders
      for headerName in extraHeaders
        xmlHttpRequest.setRequestHeader(headerName, extraHeaders[headerName])

    xmlHttpRequest.onreadystatechange = ->
      if xmlHttpRequest.readyState == 4 and xmlHttpRequest.status == 200
        callback.call(exports.window, xmlHttpRequest)
      else if xmlHttpRequest.readyState == 4
        exports.Tomahawk.log("Failed to do GET request: to: " + url)
        exports.Tomahawk.log("Status Code was: " + xmlHttpRequest.status)
    xmlHttpRequest.send(null)

exports.TomahawkResolver =
  init: ->
  scriptPath: ->
    ''
  getConfigUi: ->
    {}

  getUserConfig: ->
    {}

  saveUserConfig: ->

  newConfigSaved: ->

  resolve: (qid, artist, album, title) ->
    {qid: qid}

  search: (qid, searchString) ->
    this.resolve(qid, "", "", searchString)

  addTrackResults: (results) ->
    this.emit 'result', results
