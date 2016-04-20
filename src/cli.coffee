#! /usr/bin/env coffee
#
# cli.coffee
#
# Copyright (c) 2016 Junpei Kawamoto
#
# This software is released under the MIT License.
#
# http://opensource.org/licenses/mit-license.php
#
argv = require "argv"
scraper = require "../lib/scraper"

basename = (path) ->
  ###
  Get a basename of a path.

  ## Args
  * path: a path.

  ## Returns
  The basename of the path.
  ###
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
