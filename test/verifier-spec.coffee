{afterEach, beforeEach, context, describe, it} = global
{expect} = require 'chai'
sinon = require 'sinon'

Verifier = require '../src/verifier'
MockMeshbluSocketIO = require './mock-meshblu-socket-io'
MockMeshbluFirehoseSocketIO = require './mock-meshblu-firehose-socket-io'

describe 'Verifier', ->
  beforeEach (done) ->
    @nonce = Date.now()
    @firehoseMessageHandler = sinon.stub()

  beforeEach (done) ->
    @identityHandler = sinon.spy ->
      @emit 'ready', uuid: 'some-device', token: 'some-token'

    onConnection = (socket) =>
      socket.on 'message', (data) =>
        @messageHandler data, (response) =>
          @firehoseSocket.emit 'message', response
      socket.on 'error', (error) ->
        throw error

      socket.on 'identity', @identityHandler
      socket.emit 'identify'

    @meshblu = new MockMeshbluSocketIO port: 0xd00d, onConnection: onConnection
    @meshblu.start done

  beforeEach (done) ->
    onConnection = (@firehoseSocket) =>
      socket.on 'error', (error) ->
        throw error

    @firehose = new MockMeshbluFirehoseSocketIO port: 0xd11d, onConnection: onConnection
    @firehose.start done

  afterEach (done) ->
    @timeout 100
    @meshblu.stop => done()

  xdescribe '->verify', ->
    beforeEach ->
      meshbluConfig = protocol: 'ws', hostname: 'localhost', port: 0xd00d, resolveSrv: false
      @sut = new Verifier {meshbluConfig, @nonce}

    context 'when everything works', ->
      beforeEach 'yielding a bunch', ->
        @messageHandler.yields payload: @nonce

      beforeEach 'verify', (done) ->
        @sut.verify done

      it 'should have called all the handlers', ->
        expect(@messageHandler).to.be.called

    context 'when message fails', ->
      beforeEach (done) ->
        @messageHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@messageHandler).to.be.called
