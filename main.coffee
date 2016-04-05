#! /usr/bin/env coffee
argv = require "argv"
scraper = require "./scraper"

TEST_URL = "https://www.youtube.com/watch?v=-8sk8QfUDlQ"

basename = (path) ->
  path.split("/").reverse()[0]

argv.version 'v0.0.1'
argv.info "Usage: #{basename __filename} url [options]"

args = argv.run()
url = args.targets[0]

if url?
  scraper(url).then (res) ->
    console.log JSON.stringify
      url: url
      comments: res

else
  argv.help()
