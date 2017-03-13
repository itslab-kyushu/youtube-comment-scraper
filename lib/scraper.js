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
const SUCCESS = "success";


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

    /*
    Scraping a given Youtube page and return a set of comments.

    ## Args
    * url: URL of the target page of video ID.

    ## Returns
      Promise object. Use "then" method to receive results.
     */
    comments(url) {

        let id
        if (!url.startsWith(HTTPS) && !url.startsWith(HTTP)) {
            id = url;
            url = BASE_URL + url;
        } else {
            const sp = url.split("/");
            id = sp[sp.length - 1].substring(URL_PARAM.length);
        }

        return new Promise((resolve, reject) => {

            return phantom.get().then((ph) => {

                return ph.createPage().then((page) => {

                    return page.open(url).then((status) => {

                        if (status != SUCCESS) {
                            return Promise.reject(`Open url returns ${status}`);
                        }
                        console.warn("The video page is opened");

                        return new Promise((resolve, reject) => {

                            // Check header information has been loaded.
                            // If not, wait 1000 msec and try again, until
                            // loading is finished.
                            function check_header() {
                                // PhantomJS doesn't arrow functions.
                                page.evaluate(function() {
                                    return document.getElementsByClassName("comment-section-header-renderer").length;
                                }).then((res) => {
                                    if (res != 0) {
                                        resolve();
                                    } else {
                                        setTimeout(check_header, 1000);
                                    }
                                }).catch(reject);
                            }
                            check_header();

                        });

                    }).then(() => {
                        console.warn("Loading hidden pages and comments");

                        // PhantomJS doesn't support ES2015.
                        return page.evaluate(function() {
                            // Load hidden pages. This function clickes a
                            // load-more-button and wait 2000msec,
                            // and then do these steps while there are
                            // load-more-buttons.
                            function load_hidden_pages() {
                                var load_btns = document.getElementsByClassName("load-more-button");
                                if (load_btns.length !== 0) {
                                    load_btns[0].click();
                                    setTimeout(load_hidden_pages, 1500);
                                }
                            };
                            load_hidden_pages();
                        });

                    }).then(() => {

                        return new Promise((resolve, reject) => {

                            function get_body() {
                                // PhantomJS doesn't support arrow functions.
                                page.evaluate(function() {
                                    if (document.getElementsByClassName("load-more-button").length === 0) {
                                        return document.body.innerHTML;
                                    }
                                }).then((html) => {
                                    if (html) {
                                        resolve(html);
                                    } else {
                                        setTimeout(get_body, 10000);
                                    }
                                }).catch(reject);
                            }
                            get_body();
                        });

                    }).then((html) => {
                        page.close();
                        // TODO: fix it.

                        console.warn("Contents are loaded");
                        const $ = cheerio.load(html);
                        const res = [];

                        $(".comment-thread-renderer").each((_, elem) => {
                            const root = $(elem).children().first();
                            const children = [];
                            $(".comment-replies-renderer .comment-replies-renderer-pages .comment-renderer", this).each((_, elem) => {
                                const author = $(".comment-renderer-header", elem).children().first();
                                const child = {
                                    comment: $(".comment-renderer-text-content", elem).text(),
                                    author: author.text(),
                                    author_id: author.data("ytid"),
                                    like: check_like_score($(".comment-renderer-like-count.off", elem).text())
                                };
                                const receiver = $(".comment-renderer-text-content", elem).find("a").text();
                                if (receiver !== "") {
                                    child.receiver = receiver;
                                }
                                children.push(child);
                            });
                            const author = $(".comment-author-text", root);
                            const comment = {
                                root: $(".comment-renderer-text-content", root).text(),
                                author: author.text(),
                                author_id: author.data("ytid"),
                                like: check_like_score($(".comment-renderer-like-count.off", root).text())
                            };
                            if (children.length !== 0) {
                                comment.children = children;
                            }
                            res.push(comment);
                        });

                        const user = $(".yt-user-info a");
                        resolve({
                            id: id,
                            channel: {
                                id: user.attr("href").substring(URL_CHANNEL.length),
                                name: user.text()
                            },
                            comments: res
                        });

                    }).catch((reason) => {
                        console.error(reason);
                        page.close();
                        reject(reason);
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
                        if (status != SUCCESS) {
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
