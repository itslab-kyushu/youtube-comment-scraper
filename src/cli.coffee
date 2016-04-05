#! /usr/bin/env coffee
argv = require "argv"
scraper = require "../lib/scraper"

basename = (path) ->
  path.split("/").reverse()[0]

argv.version 'v0.0.1'
argv.info "Usage: #{basename __filename} url [options]"

args = argv.option
  name: "delay"
  short: "d"
  type: "int"
  description: "Wait time for loading all pages. (default: 30000)"
.run()
url = args.targets[0]

if url?
  delay = if args.options.delay? then args.options.delay else 30000
  scraper(url, delay).then (res) ->
    console.log JSON.stringify
      url: url
      comments: res

else
  argv.help()
