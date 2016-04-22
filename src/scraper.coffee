#
# scraper.coffee
#
# Copyright (c) 2016 Junpei Kawamoto
#
# This software is released under the MIT License.
#
# http://opensource.org/licenses/mit-license.php
#
# coffeelint: disable=max_line_length
phantom = require "phantom"
cheerio = require "cheerio"
cleanup = require "./cleanup"

BASE_URL = "https://www.youtube.com/watch?v="
HTTPS = "https://"
HTTP = "http://"


check_like_score = (value) ->
  ###
  Check like score and convert to integer if not.

  ## Args
  * value: Like score to be checked.

  ## Returns
    Integer value.
  ###
  if value? and value is not NaN
    parseInt value
  else
    0

phantom_instance = null
###
PhantomJS instances.
###

get_or_create_phantom = do ->
  ###
  Get an instance of PhantomJS.

  If there are no instances, this function creates it.
  ###
  locked = false

  _get_or_create_phantom = ->
    locked = true
    if phantom_instance?
      new Promise (resolve) ->
        resolve phantom_instance
        locked = false
    else
      phantom.create().then (instance) ->
        phantom_instance = instance
        locked = false
        return instance

  ->
    if locked
      new Promise (resolve) ->
        do wait = ->
          if locked
            setTimeout wait, 100
          else
            resolve _get_or_create_phantom()

    else
      _get_or_create_phantom()


delete_phantom = ->
  ###
  Delete PhantomJS instance.

  It is safe to call this method many times.
  ###
  if phantom_instance?
    phantom_instance.exit()
    phantom_instance = null


# Register delete_phantom method so that it will be called when
# the application ends.
cleanup ->
  delete_phantom()


module.exports = (url) ->
  ###
  Scraping a given Youtube page and return a set of comments.

  ## Args
  * url: URL of the target page of video ID.

  ## Returns
    Promise object. Use "then" method to recieve results.
  ###
  if url.substring(0, HTTPS.length) isnt HTTPS and
      url.substring(0, HTTP.length) isnt HTTP
    url = BASE_URL + url

  new Promise (resolve, reject) ->

    get_or_create_phantom().then (ph) ->

      ph.createPage().then (page) ->

        page.open(url)
          .then (status) ->
            # Check loaded page has header section.
            # If not, wait more 1000 msec.
            new Promise (resolve, reject) ->
              do check_header = ->
                page.evaluate ->
                  document.getElementsByClassName(
                    "comment-section-header-renderer").length isnt 0
                .then (res) ->
                  if res
                    resolve status
                  else
                    setTimeout check_header, 1000

                .catch (reason) ->
                  reject reason

          .then (status) ->
            page.evaluate ->
              load_hidden_pages = (delay, callback) ->
                # Load hidden pages.
                #
                # Args:
                #   delay: Wait time for loading a new page.
                #   callback: function called when all pages will be loded.
                do load = ->
                  load_btns = document.getElementsByClassName("load-more-button")
                  if load_btns.length is 0
                    callback()
                  else
                    load_btns[0].click()
                    setTimeout load, delay

              # 1000 msec seems enough to load each page.
              load_hidden_pages 1000, ->
                # Load omitted comments.
                for read_more in document.getElementsByClassName("read-more")
                  read_more.firstElementChild.click()

                document.body.dataset.youtubeCommentScraper = "ready"

          .then ->
            # Check data-youtube-comment-scraper is ready, which means all pages
            # are loaded and all collapsed comments are expanded.
            # If not, wait more 1000 msec.
            new Promise (resolve, reject) ->
              do get_body = ->
                page.evaluate ->
                  if document.body.dataset.youtubeCommentScraper is "ready"
                    document.body.innerHTML
                .then (html) ->
                  if html
                    resolve html
                  else
                    setTimeout get_body, 1000

                .catch (reason) ->
                  reject reason

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
                  author: $(@).data("author-name")
                  receiver: $(".comment-renderer-text-content", @).find("a").text()

              res.push
                root: $(".comment-renderer-text-content", root).text()
                author: root.data("author-name")
                like: check_like_score $(".comment-renderer-like-count.off", root).text()
                children: children

            # Clean up.
            page.close()
            resolve res

          .catch (reason) ->
            console.error reason

            # Clean up.
            page.close()
            reject reason


module.exports.close = delete_phantom
###
Close this module.

This function should be called to close PhantomJS processes.
###
