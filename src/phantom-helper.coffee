#
# phantom-helper.coffee
#
# Copyright (c) 2016 Junpei Kawamoto
#
# This software is released under the MIT License.
#
# http://opensource.org/licenses/mit-license.php
#

###
Ensure creating only one PhantomJS instance.

###
phantom = require "phantom"
cleanup = require "./cleanup"

phantom_instance = null
###
The PhantomJS instances.
###

module.exports =

  get: do ->
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


  delete: ->
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
  module.exports.delete()
