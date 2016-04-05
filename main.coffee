#! /usr/bin/env coffee
scraper = require "./scraper"


TEST_URL = "https://www.youtube.com/watch?v=-8sk8QfUDlQ"


scraper(TEST_URL).then (res) ->
  console.log JSON.stringify
    url: TEST_URL
    comments: res
