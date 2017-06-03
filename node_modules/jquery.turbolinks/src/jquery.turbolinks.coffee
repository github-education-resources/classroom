###
jQuery.Turbolinks ~ https://github.com/kossnocorp/jquery.turbolinks
jQuery plugin for drop-in fix binded events problem caused by Turbolinks

The MIT License
Copyright (c) 2012-2013 Sasha Koss & Rico Sta. Cruz
###

$ = window.jQuery or require?('jquery')
$document = $(document)

$.turbo =
  version: '2.1.0'

  isReady: false

  # Hook onto the events that Turbolinks triggers.
  use: (load, fetch) ->
    $document
      .off('.turbo')
      .on("#{load}.turbo", @onLoad)
      .on("#{fetch}.turbo", @onFetch)

  addCallback: (callback) ->
    if $.turbo.isReady
      callback($)
    $document.on 'turbo:ready', -> callback($)

  onLoad: ->
    $.turbo.isReady = true
    $document.trigger('turbo:ready')

  onFetch: ->
    $.turbo.isReady = false

  # Registers jQuery.Turbolinks by monkey-patching jQuery's
  # `ready` handler. (Internal)
  #
  # [1] Trigger the stored `ready` events on first load.
  # [2] Override `$(function)` and `$(document).ready(function)` by
  #     registering callbacks under a new event called `turbo:ready`.
  #
  register: ->
    $(@onLoad) #[1]
    $.fn.ready = @addCallback #[2]

# Use with Turbolinks.
$.turbo.register()
$.turbo.use('page:load', 'page:fetch')
