#! /usr/bin/env coffee
# coffeelint: disable=max_line_length
phantom = require "phantom"
cheerio = require "cheerio"

url = "https://www.youtube.com/watch?v=-8sk8QfUDlQ"

wait = (delay) ->
  (args) ->
    new Promise (resolve, reject) ->
      setTimeout ->
        resolve args
      , delay


phantom.create().then (ph) ->

  ph.createPage().then (page) ->

    page.open(url)
      .then wait(10000)
      .then (status) ->
        page.evaluate ->

          load_hidden_page = (delay, callback) ->
            # Load hidden pages.
            # Args:
            #   delay:
            # Returns:
            #  Promise object so that follwing logics could be written in "then".
            load = ->
              load_btns = document.getElementsByClassName("load-more-button")
              if load_btns.length is 0
                callback()
              else
                load_btns[0].click()
                setTimeout load, delay
            setTimeout load, delay

          load_hidden_page 2000, ->
            # Load omitted comments.
            for read_more in document.getElementsByClassName("read-more")
              read_more.firstElementChild.click()

      .then wait(30000)
      .then ->
        page.evaluate ->
          return document.body.innerHTML

      .then (html) ->
        $ = cheerio.load html
        $(".comment-thread-renderer").each (i) ->
          console.log i, $(".comment-renderer-text-content", $(@).children().first()).text()

        # console.log res
        page.close()
        ph.exit()
      .catch (reason) ->
        console.error reason
        page.close()
        ph.exit()
