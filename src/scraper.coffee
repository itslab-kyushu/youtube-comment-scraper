# coffeelint: disable=max_line_length
phantom = require "phantom"
cheerio = require "cheerio"


module.exports = (url, wait_time=30000) ->
  # Scraping a given Youtube page and return a set of comments.
  #
  # Args:
  #   url: URL of the target page.
  #   wait_time: Wait time for loading all comment. (Default: 30000msec)
  #
  # Returns:
  #   Promise object. Use "then" to recieve results.
  wait = (delay) ->
    # Wait timer for Promise chain.
    #
    # Results of previous function will be passed to the next function.
    #
    # Args:
    #   delay: Wait time (msec)
    #
    # Returns:
    #   Promise object.
    (args) ->
      new Promise (resolve, _) ->
        setTimeout ->
          resolve args
        , delay

  check_like_score = (value) ->
    # Check like score and convert to integer if not.
    #
    # Args:
    #   value: Like score to be checked.
    #
    # Returns:
    #   Integer value.
    if value? and value is not NaN
      parseInt value
    else
      0

  new Promise (resolve, inject) ->

    phantom.create().then (ph) ->

      ph.createPage().then (page) ->

        page.open(url)
          .then wait(10000)
          .then (status) ->
            page.evaluate ->

              load_hidden_pages = (delay, callback) ->
                # Load hidden pages.
                #
                # Args:
                #   delay: Wait time for loading a new page.
                #   callback: function called when all pages will be loded.
                load = ->
                  load_btns = document.getElementsByClassName("load-more-button")
                  if load_btns.length is 0
                    callback()
                  else
                    load_btns[0].click()
                    setTimeout load, delay
                setTimeout load, delay

              # 2000 msec seems enough to load each page.
              load_hidden_pages 2000, ->

                # Load omitted comments.
                for read_more in document.getElementsByClassName("read-more")
                  read_more.firstElementChild.click()

          .then wait(wait_time)
          .then ->
            page.evaluate ->
              return document.body.innerHTML

          .then (html) ->
            $ = cheerio.load html
            res = []
            $(".comment-thread-renderer").each ->
              root = $(@).children().first()

              children = []
              $(".comment-replies-renderer .comment-renderer", @).each (i) ->
                children.push
                  comment: $(".comment-renderer-text-content", @).text()
                  like: check_like_score $(".comment-renderer-like-count.off", @).text()

              res.push
                root: $(".comment-renderer-text-content", root).text()
                like: check_like_score $(".comment-renderer-like-count.off", root).text()
                children: children

            # Clean up.
            page.close()
            ph.exit()

            resolve res

          .catch (reason) ->
            console.error reason

            # Clean up.
            page.close()
            ph.exit()

            reject reason
