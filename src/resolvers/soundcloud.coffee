###

  SoundCloud playdar resolver, adapted from Tomahawk resovlers repository.

  (c) 2012 Thierry Göckel <thierry@strayrayday.lu>
  (c) 2013 Andrey Popp <8mayday@gmail.com>
###

{BaseResolver} = require '../resolver'

capitalize = (s) ->
  s.replace(/(^|\s)([a-z])/g , (m, p1, p2) -> p1 + p2.toUpperCase())

removeQuotes = (s) ->
  s.replace('"', '').replace("'", "")

class exports.Resolver extends BaseResolver

  settings:
    name: 'soundcloud'
    weight: 85
    timeout: 15
    includeCovers: false
    includeRemixes: false
    includeLive: false
    clientID: '6fbc2e93c1ce8b25cc6f5c18b68bbce4'
    useEchonest: true
    echonestAPIKey: 'JRIHWEP6GPOER2QQ6'

  isTrack: (trackTitle, origTitle) ->
    if (this.settings.includeCovers == false or this.settings.includeCovers == undefined) \
        and trackTitle.search(/cover/i) != -1 \
        and origTitle.search(/cover/i) == -1
      false

    if (this.settings.includeRemixes == false or this.settings.includeRemixes == undefined) \
        and trackTitle.search(/(re)*mix/i) != -1 \
        and origTitle.search(/(re)*mix/i) == -1
      false

    if (this.settings.includeLive == false or this.settings.includeLive == undefined) \
        and trackTitle.search(/live/i) != -1 \
        and origTitle.search(/live/i) == -1
      false

    else
      true

  resolve: (qid, artist, title) ->
    if artist != ""
      query = artist + " "

    if title != ""
      query = query + title

    params =
      client_id: this.settings.clientID
      filter: 'streamable'
      q: query

    this.request "http://api.soundcloud.com/tracks.json", params, (error, resp, body) =>

      data = JSON.parse(body)

      if error or resp.statusCode != 200
        return this.end(qid: qid)

      if data.length == 0
        return this.end(qid: qid)

      results = for r in data
        # Need some more validation here.
        # This doesnt help it seems, or it just
        # throws the error anyhow, and skips?
        if r == undefined
          continue

        if !r.streamable # Check for streamable tracks only
          continue

        # Check whether the artist and title (if set) are in the returned
        # title, discard otherwise But also, the artist could be the username
        if r.title != undefined \
            and (
              r.title.toLowerCase().indexOf(artist.toLowerCase()) == -1 \
              or r.title.toLowerCase().indexOf(title.toLowerCase()) == -1)
          continue

        result = {}
        result.artist = artist

        if this.isTrack(r.title, title)
          result.track = title
        else
          continue

        result.source = this.settings.name
        result.mimetype = "audio/mpeg"
        result.bitrate = 128
        result.duration = r.duration / 1000
        result.score = 0.85
        result.year = r.release_year
        result.url = "#{r.stream_url}.json?client_id=#{this.settings.clientID}"

        if r.permalink_url != undefined
          result.linkUrl = r.permalink_url

        result

      this.results {qid: qid, results: [results[0]]}

  search: (qid, searchString) ->
    url = "http://api.soundcloud.com/tracks.json"
    params =
      client_id: this.settings.clientID
      filter: 'streamable'
      q: removeQuotes(searchString)

    this.request url, params, (error, resp, body) =>

      if error or resp.statusCode != 200

        errorDetails = if error
          error
        else
          JSON.parse(resp.body)

        this.end
          qid: qid
          reason:
            msg: 'error querying service'
            details: errorDetails
        return

      data = JSON.parse(body)

      if data.length == 0
        return this.end(qid: qid)

      results = for r, i in data

        result = {}

        if not this.isTrack(r.title, '')
          continue

        track = r.title

        if track.indexOf(" - ") != -1 and track.slice(track.indexOf(" - ") + 3).trim() != ""
          result.track = track.slice(track.indexOf(" - ") + 3).trim()
          result.artist = track.slice(0, track.indexOf(" - ")).trim()

        else if track.indexOf(" -") != -1 and track.slice(track.indexOf(" -") + 2).trim() != ""
          result.track = track.slice(track.indexOf(" -") + 2).trim()
          result.artist = track.slice(0, track.indexOf(" -")).trim()

        else if track.indexOf(": ") != -1 and track.slice(track.indexOf(": ") + 2).trim() != ""
          result.track = track.slice(track.indexOf(": ") + 2).trim()
          result.artist = track.slice(0, track.indexOf(": ")).trim()

        else if track.indexOf("-") != -1 and track.slice(track.indexOf("-") + 1).trim() != ""
          result.track = track.slice(track.indexOf("-") + 1).trim()
          result.artist = track.slice(0, track.indexOf("-")).trim()

        else if track.indexOf(":") != -1 and track.slice(track.indexOf(":") + 1).trim() != ""
          result.track = track.slice(track.indexOf(":") + 1).trim()
          result.artist = track.slice(0, track.indexOf(":")).trim()

        else if track.indexOf("\u2014") != -1 and track.slice(track.indexOf("\u2014") + 2).trim() != ""
          result.track = track.slice(track.indexOf("\u2014") + 2).trim()
          result.artist = track.slice(0, track.indexOf("\u2014")).trim()

        else if r.title != "" and r.user.username != ""
          # Last resort, the artist is the username
          result.track = r.title
          result.artist = r.user.username

        else
          continue

        result.source = this.settings.name
        result.mimetype = "audio/mpeg"
        result.bitrate = 128
        result.duration = r.duration / 1000
        result.score = 0.85
        result.year = r.release_year
        result.url = "#{r.stream_url}.json?client_id=#{this.settings.clientID}"
        result.linkUrl = r.permalink_url if r.permalink_url

        result

      if not this.settings.useEchonest
        this.result(qid: qid, results: results)
        this.end(qid: qid)

      else
        this.queryEchonest(qid, results)

  queryEchonest: (qid, results) ->
    stop = results.length
    refinedResults = []
    for result, i in results
      do (result, i) =>
        params =
          api_key: this.settings.echonestAPIKey
          format: 'json'
          results: 1
          sort: 'hotttnesss-desc'
          text: capitalize(result.artist)

        this.request "http://developer.echonest.com/api/v4/artist/extract", params, (error, resp, body) =>
          stop = stop - 1

          if not error and resp.statusCode == 200
            response = JSON.parse(body).response

            if response and response.artists and response.artists.length > 0
              artist = response.artists[0].name
              result.artist = artist
              result.id = i
              refinedResults.push(result)

          if stop == 0
            refinedResults = refinedResults.sort (a, b) -> a.id - b.id

            for rj in refinedResults
              delete rj.id

            this.result {results: refinedResults, qid: qid}
            this.end(qid: qid)
