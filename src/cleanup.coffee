#
# cleanup.coffee
#
# This file is converted from a post in stackoverflow by CanyonCasa.
# URL:
# http://stackoverflow.com/questions/14031763/doing-a-cleanup-action-just-before-node-js-exits
#
no_op = ->
  ###
  No operation function.
  ###

module.exports = (callback=no_op) ->
  ###
  Register cleanup function.

  ## Args
  * callback: A callback function to be called then the application ends.
  ###

  # attach user callback to the process event emitter
  # if no callback, it will still exit gracefully on Ctrl-C
  process.on "cleanup", callback

  # do app specific cleaning before exiting
  process.on "exit", ->
    process.emit "cleanup"

  # catch ctrl+c event and exit normally
  process.on "SIGINT", ->
    console.log "Ctrl-C..."
    process.exit 2

  # catch uncaught exceptions, trace, then exit normally
  process.on "uncaughtException", (e) ->
    console.log "Uncaught Exception..."
    console.log e.stack
    process.exit 99
