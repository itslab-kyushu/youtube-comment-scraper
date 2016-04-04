#! /usr/bin/env coffee
# coffeelint: disable=max_line_length
phantom = require "phantom"
cheerio = require "cheerio"

url = "https://www.youtube.com/watch?v=-8sk8QfUDlQ"

wait = (delay) ->
  (pass) ->
    new Promise (resolve, reject) ->
      setTimeout ->
        resolve pass
      , delay


phantom.create().then (ph) ->

  ph.createPage().then (page) ->

    page.open(url)
      .then wait(10000)
      .then (status) ->
        page.evaluate ->

          # Load hided contents.
          loop
            load_btns = document.getElementsByClassName("load-more-button")
            break if load_btns.length is 0
            load_btns[0].click()

          # Load omitted comments.
          for read_more in document.getElementsByClassName("comment-text-toggle-link")
            read_more.firstElementChild.click()

          res = []
          for thread in document.getElementsByClassName("comment-thread-renderer")
            root = thread.firstElementChild
            res.push(root.getElementsByClassName("comment-renderer-text-content")[0].innerText)
          return res
      .then (res) ->
        console.log res
        page.close()
        ph.exit()
      .catch (reason) ->
        console.error "error", reason
        page.close()
        ph.exit()
