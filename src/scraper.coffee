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
cheerio = require "cheerio"
phantom = require "./phantom-helper"

BASE_URL = "https://www.youtube.com/watch?v="
HTTPS = "https://"
HTTP = "http://"
URL_PARAM = "watch?v="
URL_CHANNEL = "/channel/"

check_like_score = (value) ->
  ###
  Check like score and convert to integer if not.

  ## Args
  * value: Like score to be checked.

  ## Returns
    Integer value.
  ###
  if value?
    res = parseInt value, 10
    if not isNaN res
      return res
  return 0


module.exports =

  comments: (url) ->
    ###
    Scraping a given Youtube page and return a set of comments.

    ## Args
    * url: URL of the target page of video ID.

    ## Returns
      Promise object. Use "then" method to receive results.
    ###
    if url.substring(0, HTTPS.length) isnt HTTPS and
        url.substring(0, HTTP.length) isnt HTTP
      id = url
      url = BASE_URL + url
    else
      sp = url.split("/")
      id = sp[sp.length - 1].substring(URL_PARAM.length)

    new Promise (resolve, reject) ->

      phantom.get().then (ph) ->

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
                  for read_more in document.getElementsByClassName("comment-replies-renderer-expander-down")
                    # read_more.firstElementChild.click()
                    read_more.click()

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
              # Close the page and release resources.
              page.close()

              $ = cheerio.load html

              res = []
              $(".comment-thread-renderer").each ->
                root = $(@).children().first()

                children = []
                $(".comment-replies-renderer .comment-replies-renderer-pages .comment-renderer", @).each (i) ->
                  child =
                    comment: $(".comment-renderer-text-content", @).text()
                    like: check_like_score $(".comment-renderer-like-count.off", @).text()
                    author: $(@).data("author-name")
                  receiver = $(".comment-renderer-text-content", @).find("a").text()
                  if receiver isnt ""
                    child.receiver = receiver
                  children.push child

                comment =
                  root: $(".comment-renderer-text-content", root).text()
                  author: root.data("author-name")
                  like: check_like_score $(".comment-renderer-like-count.off", root).text()
                if children.length isnt 0
                  comment.children = children
                res.push comment


              user = $(".yt-user-info a")
              resolve
                id:id
                channel:
                  id: user.attr("href").substring URL_CHANNEL.length
                  name: user.text()
                comments: res

            .catch (reason) ->
              console.error reason

              # Clean up.
              page.close()
              reject reason


  channel: (id) ->
    ###
    Scraping a Youtube channel page and return a description of the channel.

    ## Args
    * id: channel ID.

    ## Returns
      Promise object. Use "then" method to receive results.
    ###
    url = "https://www.youtube.com/channel/#{id}/about"
    new Promise (resolve, reject) ->

      phantom.get().then (ph) ->

        ph.createPage().then (page) ->

          page.open(url)
            .then ->
              page.evaluate ->
                document.body.innerHTML

            .then (html) ->
              # Close the page and release resources.
              page.close()

              $ = cheerio.load html
              resolve
                id: id
                name: $(".qualified-channel-title-text").text()
                description: $(".about-description").text().replace(/^\s+|\s+$/g, "")

            .catch (reason) ->
              console.error reason
              page.close()
              reject reason

  close: phantom.delete
  ###
  Close this module.

  This function should be called to close PhantomJS processes.
  ###
