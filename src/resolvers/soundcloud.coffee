###

  SoundCloud playdar resolver, adapted from Tomahawk resovlers repository.

  (c) 2012 Thierry Göckel <thierry@strayrayday.lu>
  (c) 2013 Andrey Popp <8mayday@gmail.com>
###

{BaseResolver} = require '../resolver'

capitalize = (s) ->
  s.replace(/(^|\s)([a-z])/g , (m, p1, p2) -> p1 + p2.toUpperCase())

class exports.Resolver extends BaseResolver

  settings:
    name: 'soundcloud'
    weight: 85
    timeout: 15
    includeCovers: false
    includeRemixes: false
    includeLive: false
    echonestAPIKey: 'JRIHWEP6GPOER2QQ6'
    clientID: 'TiNg2DRYhBnp01DA3zNag'
    consumerKey: 'TiNg2DRYhBnp01DA3zNag'

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

  resolve: (qid, artist, album, title) ->
    if artist != ""
      query = artist + " "

    if title != ""
      query = query + title

    params =
      consumer_key: this.settings.consumerKey
      filter: 'streamable'
      q: query

    this.request "http://api.soundcloud.com/tracks.json", params, (error, resp, body) =>

      data = JSON.parse(body)

      if error or resp.statusCode != 200
        this.end(qid: qid)
        return

      if data.length == 0
        this.end(qid: qid)
        return

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
      consumer_key: this.settings.consumerKey
      filter: 'streamable'
      q: searchString.replace('"', '').replace("'", "")

    this.request url, params, (error, resp, body) ->

      if error or resp.statusCode != 200
        this.end(qid: qid)
        return

      data = JSON.parse(body)

      if data.length != 0

        results = []
        stop = data.length

        for r in data

          if r == undefined
            stop = stop - 1
            continue

          result = {}

          if this.isTrack(r.title, "")
            track = r.title

            if track.indexOf(" - ") != -1 and track.slice(track.indexOf(" - ") + 3).trim() != ""
              result.track = track.slice(track.indexOf(" - ") + 3).trim();
              result.artist = track.slice(0, track.indexOf(" - ")).trim();

            else if track.indexOf(" -") != -1 and track.slice(track.indexOf(" -") + 2).trim() != ""
              result.track = track.slice(track.indexOf(" -") + 2).trim();
              result.artist = track.slice(0, track.indexOf(" -")).trim();

            else if track.indexOf(": ") != -1 and track.slice(track.indexOf(": ") + 2).trim() != ""
              result.track = track.slice(track.indexOf(": ") + 2).trim();
              result.artist = track.slice(0, track.indexOf(": ")).trim();

            else if track.indexOf("-") != -1 and track.slice(track.indexOf("-") + 1).trim() != ""
              result.track = track.slice(track.indexOf("-") + 1).trim();
              result.artist = track.slice(0, track.indexOf("-")).trim();

            else if track.indexOf(":") != -1 and track.slice(track.indexOf(":") + 1).trim() != ""
              result.track = track.slice(track.indexOf(":") + 1).trim();
              result.artist = track.slice(0, track.indexOf(":")).trim();

            else if track.indexOf("\u2014") != -1 and track.slice(track.indexOf("\u2014") + 2).trim() != ""
              result.track = track.slice(track.indexOf("\u2014") + 2).trim();
              result.artist = track.slice(0, track.indexOf("\u2014")).trim();

            else if r.title != "" and r.user.username != ""
              # Last resort, the artist is the username
              result.track = r.title;
              result.artist = r.user.username;

            else
              stop = stop - 1
              continue

          else
            stop = stop - 1
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

          do (i, result) =>
            params =
              api_key: this.settings.echonestAPIKey
              format: 'json'
              results: 1
              sort: 'hotttnesss-desc'
              text: capitalize(result.artist)

            this.request "http://developer.echonest.com/api/v4/artist/extract", params, (error, resp, body) =>
              if not error and resp.statusCode == 200
                dataonse = JSON.parse(body).dataonse
                if dataonse and dataonse.artists and dataonse.artists.length > 0
                  artist = dataonse.artists[0].name
                  result.artist = artist
                  result.id = i
                  results.push(result)
                  stop = stop - 1
                else
                  stop = stop - 1

                if stop == 0
                  sortResults = (a, b) ->
                    a.id - b.id
                  results = results.sort(sortResults)

                  for rj in results
                    delete rj.id

                  this.results {results: results, qid: qid}

        if stop == 0
          this.end(qid: qid)
      else
        this.end(qid: qid)

exports.test = ->
  r = new exports.Resolver({})
  r.on 'results', (m) -> console.log m
  r.search('qid', 'cherry eye')
