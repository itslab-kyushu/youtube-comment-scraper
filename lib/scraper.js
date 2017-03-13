//
// scraper.js
//
// Copyright (c) 2016-2017 Junpei Kawamoto
//
// This software is released under the MIT License.
//
// http://opensource.org/licenses/mit-license.php
//
const cheerio = require("cheerio");
const phantom = require("./phantom-helper");
const BASE_URL = "https://www.youtube.com/watch?v=";
const HTTPS = "https://";
const HTTP = "http://";
const URL_PARAM = "watch?v=";
const URL_CHANNEL = "/channel/";


/*
Check like score and convert to integer if not.

## Args
* value: Like score to be checked.

## Returns
  Integer value.
 */
function check_like_score(value) {
    if (value != null) {
        const res = parseInt(value, 10);
        if (!isNaN(res)) {
            return res;
        }
    }
    return 0;
};

module.exports = {
    comments: function(url) {

        /*
        Scraping a given Youtube page and return a set of comments.

        ## Args
        * url: URL of the target page of video ID.

        ## Returns
          Promise object. Use "then" method to receive results.
         */
        var id, sp;
        if (url.substring(0, HTTPS.length) !== HTTPS && url.substring(0, HTTP.length) !== HTTP) {
            id = url;
            url = BASE_URL + url;
        } else {
            sp = url.split("/");
            id = sp[sp.length - 1].substring(URL_PARAM.length);
        }
        return new Promise(function(resolve, reject) {
            return phantom.get().then(function(ph) {
                return ph.createPage().then(function(page) {
                    return page.open(url).then(function(status) {
                        return new Promise(function(resolve, reject) {
                            var check_header;
                            return (check_header = function() {
                                return page.evaluate(function() {
                                    return document.getElementsByClassName("comment-section-header-renderer").length !== 0;
                                }).then(function(res) {
                                    if (res) {
                                        return resolve(status);
                                    } else {
                                        return setTimeout(check_header, 1000);
                                    }
                                })["catch"](function(reason) {
                                    return reject(reason);
                                });
                            })();
                        });
                    }).then(function(status) {
                        return page.evaluate(function() {
                            var load_hidden_pages;
                            load_hidden_pages = function(delay, callback) {
                                var load;
                                return (load = function() {
                                    var load_btns;
                                    load_btns = document.getElementsByClassName("load-more-button");
                                    if (load_btns.length === 0) {
                                        return callback();
                                    } else {
                                        load_btns[0].click();
                                        return setTimeout(load, delay);
                                    }
                                })();
                            };
                            return load_hidden_pages(1000, function() {
                                var j, len, read_more, ref;
                                ref = document.getElementsByClassName("comment-replies-renderer-expander-down");
                                for (j = 0, len = ref.length; j < len; j++) {
                                    read_more = ref[j];
                                    read_more.click();
                                }
                                return document.body.dataset.youtubeCommentScraper = "ready";
                            });
                        });
                    }).then(function() {
                        return new Promise(function(resolve, reject) {
                            var get_body;
                            return (get_body = function() {
                                return page.evaluate(function() {
                                    if (document.body.dataset.youtubeCommentScraper === "ready") {
                                        return document.body.innerHTML;
                                    }
                                }).then(function(html) {
                                    if (html) {
                                        return resolve(html);
                                    } else {
                                        return setTimeout(get_body, 1000);
                                    }
                                })["catch"](function(reason) {
                                    return reject(reason);
                                });
                            })();
                        });
                    }).then(function(html) {
                        var $, res, user;
                        page.close();
                        $ = cheerio.load(html);
                        res = [];
                        $(".comment-thread-renderer").each(function() {
                            var author, children, comment, root;
                            root = $(this).children().first();
                            children = [];
                            $(".comment-replies-renderer .comment-replies-renderer-pages .comment-renderer", this).each(function(i) {
                                var author, child, receiver;
                                author = $(".comment-renderer-header", this).children().first();
                                child = {
                                    comment: $(".comment-renderer-text-content", this).text(),
                                    author: author.text(),
                                    author_id: author.data("ytid"),
                                    like: check_like_score($(".comment-renderer-like-count.off", this).text())
                                };
                                receiver = $(".comment-renderer-text-content", this).find("a").text();
                                if (receiver !== "") {
                                    child.receiver = receiver;
                                }
                                return children.push(child);
                            });
                            author = $(".comment-renderer-header", root).children().first();
                            comment = {
                                root: $(".comment-renderer-text-content", root).text(),
                                author: author.text(),
                                author_id: author.data("ytid"),
                                like: check_like_score($(".comment-renderer-like-count.off", root).text())
                            };
                            if (children.length !== 0) {
                                comment.children = children;
                            }
                            return res.push(comment);
                        });
                        user = $(".yt-user-info a");
                        return resolve({
                            id: id,
                            channel: {
                                id: user.attr("href").substring(URL_CHANNEL.length),
                                name: user.text()
                            },
                            comments: res
                        });
                    })["catch"](function(reason) {
                        console.error(reason);
                        page.close();
                        return reject(reason);
                    });
                });
            });
        });
    },

    /*
    Scraping a Youtube channel page and return a description of the channel.

    ## Args
    * id: channel ID.

    ## Returns
      Promise object. Use "then" method to receive results.
     */
    channel(id) {
        let url;
        if (id.startsWith(HTTP) || id.startsWith(HTTPS)) {
            if (!id.endsWith("/about")) {
                url = id + "/about";
            } else {
                url = id;
            }
        } else {
            url = "https://www.youtube.com/channel/" + id + "/about";
        }

        return new Promise((resolve, reject) => {

            return phantom.get().then((ph) => {

                return ph.createPage().then((page) => {

                    return page.open(url).then((status) => {
                        if (status != "success") {
                            return Promise.reject(`Open url returns ${status}.`)
                        }
                        // PhantomJS doesn't support ES2015.
                        return page.evaluate(function() {
                            return document.body.innerHTML;
                        });
                    }).then((html) => {
                        page.close();
                        const $ = cheerio.load(html);
                        resolve({
                            id: id,
                            name: $(".qualified-channel-title-text").text(),
                            description: $(".about-description").text().replace(/^\s+|\s+$/g, "")
                        });
                    }).catch((err) => {
                        console.error(err);
                        page.close();
                        reject(reason);
                    });
                });
            });
        });
    },

    /*
    Close this module.

    This function should be called to close PhantomJS processes.
     */
    close: phantom.close

};
