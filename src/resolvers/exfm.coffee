###
  (c) 2011 lasconic <lasconic@gmail.com>
  (c) 2011 Andrey Popp <8mayday@gmail.com>
###

{BaseResolver} = require '../resolver'

class exports.Resolver extends BaseResolver

  settings:
    name: 'exfm'
    weight: 30
    timeout: 5

  resolve: (qid, artist, album, title) ->
    # build query to 4shared
    url = "http://ex.fm/api/v3/song/search/#{encodeURIComponent(title)}"
    params =
      start: 0
      results: 20

    this.request url, params, (error, resp, body) =>
      response = JSON.parse(body)
      results = []

      if response.results > 0
        songs = response.songs

        for song in songs
          result = {}

          if song.url.indexOf("http://api.soundcloud") == 0
            # unauthorised, use soundcloud resolver instead
            continue

          if song.artist != null

            if song.title != null

              dTitle = ""
              if song.title.indexOf("\n") != -1
                stringArray = song.title.split("\n")
                newTitle = ""
                for sa in stringArray
                  newTitle += sa.trim() + " "
                dTitle = newTitle.trim()
              else
                dTitle = song.title

              dTitle = dTitle
                .replace("\u2013","")
                .replace("  ", " ")
                .replace("\u201c","")
                .replace("\u201d","")

              if dTitle.toLowerCase().indexOf(song.artist.toLowerCase() + " -") == 0
                dTitle = dTitle.slice(song.artist.length + 2).trim()
              else if dTitle.toLowerCase().indexOf(song.artist.toLowerCase() + "-") == 0
                dTitle = dTitle.slice(song.artist.length + 1).trim()
              else if dTitle.toLowerCase() == song.artist.toLowerCase()
                continue
              else if dTitle.toLowerCase().indexOf(song.artist.toLowerCase()) == 0
                dTitle = dTitle.slice(song.artist.length).trim()
              dArtist = song.artist
          else
            continue
          if song.album != null
            dAlbum = song.album

          if dTitle.toLowerCase().indexOf(title.toLowerCase()) != -1 \
              and dArtist.toLowerCase().indexOf(artist.toLowerCase()) != -1 \
              or artist == "" and album == ""
            result.artist = if dArtist != "" then dArtist else artist
            result.album = if dAlbum != "" then dAlbum else album
            result.track = if dTitle != "" then dTitle else title
            result.source = this.settings.name
            result.url = song.url
            result.extension = "mp3"
            result.score = 0.80
            results.push(result)

          if artist != ""
            # resolve, return only one result
            break

      this.result(qid: qid, results: results)
      this.end(qid: qid)

  search: (qid, searchString) ->
    this.settings.strictMatch = false
    this.resolve(qid, "", "", searchString)
