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
        console.log "ev"
        page.evaluate ->

          console.log "def load_hidden"
          load_hidden_page = (delay) ->
            # Load hidden pages.
            # Args:
            #   delay:
            # Returns:
            #  Promise object so that follwing logics could be written in "then".
            new Promise (resolve, reject) ->
              checker = ->
                load_btns = document.getElementsByClassName("load-more-button")
                if load_btns.length is 0
                  resolve()
                else
                  load_btns[0].click()
                  setTimeout checker, delay
              setTimeout checker, delay

          load_hidden_page 1000
            .then ->

              console.log "finished loading"

              # Load omitted comments.
              for read_more in document.getElementsByClassName("read-more")
                read_more.firstElementChild.click()

              console.log "comments"
              return document.getElementsByClassName("comment-thread-renderer")
              # res = []
              # for thread in document.getElementsByClassName("comment-thread-renderer")
              #   root = thread.firstElementChild
              #   res.push(root.getElementsByClassName("comment-renderer-text-content")[0].innerText)
              # return res

          return null
      .then (res) ->
        console.log res
        page.close()
        ph.exit()
      .catch (reason) ->
        console.error reason
        page.close()
        ph.exit()
