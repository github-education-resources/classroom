before (next) ->
  require('jsdom').env
    html: "<!doctype html><html><head><meta charset='utf-8'></head><body></body></html>",
    done: (errors, window) ->
      global.window = window
      global.document = window.document
      if (errors)
        errors.forEach(console.error)
        throw new Error(errors[0].data.error + " (" + errors[0].data.filename + ")")
      next()

before ->
  global.$ = require('jquery')
  global.jQuery = require('jquery')
  require('../src/jquery.turbolinks.coffee')

chai      = require('chai')
sinon     = require('sinon')
sinonChai = require('sinon-chai')

chai.should()
chai.use(sinonChai)

getUniqId = do ->
  counter = 0
  -> 'id_' + (counter += 1)

describe '$ Turbolinks', ->

  callback1 = callback2 = null

  # Simulate a reset.
  beforeEach ->
    $.turbo.isReady = false
    $.turbo.use 'page:load', 'page:fetch'
    $(document).off('turbo:ready')

  describe "DOM isn't ready", ->

    beforeEach ->
      $(callback1 = sinon.spy())
      $(callback2 = sinon.spy())

    it '''
         should trigger callbacks passed to
         `$()` and `$.ready()` when page:load
         event fired
       ''', ->
         $(document).trigger('page:load')

         callback1.should.have.been.calledOnce
         callback2.should.have.been.calledOnce

    it 'should pass $ as the first argument to callbacks', (done) ->
      $ ($$) ->
        $$.fn.should.be.an.object
        done()

      $(document).trigger 'page:load'

    describe '$.turbo.use', ->
      beforeEach ->
        $.turbo.use('page:load', 'page:fetch')

      it 'should unbind default (page:load) event', ->
        $.turbo.use('other1', 'other2')

        $(document).trigger('page:load')

        callback1.should.have.not.been.called
        callback2.should.have.not.been.called

      it 'should bind ready to passed function', ->
        $(document)
          .trigger('page:load')
          .trigger('page:change')

        callback1.should.have.been.calledOnce
        callback2.should.have.been.calledOnce

    describe '$.setFetchEvent', ->

      beforeEach ->
        $.turbo.use('page:load', 'page:fetch')
        $.turbo.isReady = true

      it 'should unbind default (page:fetch) event', ->
        $.turbo.use('page:load', 'random_event_name')
        $(document).trigger('page:fetch')
        $.turbo.isReady.should.to.be.true

      it 'should bind passed fetch event', ->
        $.turbo.use('page:load', 'page:loading')
        $(document).trigger('page:loading')
        $.turbo.isReady.should.to.be.false

  describe 'DOM is ready', ->

    beforeEach ->
      $.turbo.use('page:load', 'page:fetch')
      $.turbo.isReady = true

    it 'should call trigger right after add to waiting list', ->
      $(callback = sinon.spy())
      callback.should.have.been.calledOnce

    it 'should not call trigger after page:fetch and before page:load', ->
      $(document).trigger('page:fetch')
      $(callback1 = sinon.spy())
      callback1.should.have.not.been.called

      $(document).trigger('page:load')
      $(callback2 = sinon.spy())
      callback2.should.have.been.calledOnce

    it 'should call trigger after a subsequent page:fetch and before page:load', ->
      $(document).trigger('page:fetch')
      $(document).trigger('page:load')
      $(callback1 = sinon.spy())
      callback1.should.have.been.calledOnce
      $(document).trigger('page:fetch')
      $(document).trigger('page:load')
      callback1.should.have.been.calledTwice

    it 'should pass $ as the first argument to callbacks', (done) ->
      $ ($$) ->
        $$.fn.should.be.an.object
        done()
