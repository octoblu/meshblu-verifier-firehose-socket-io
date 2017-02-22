{afterEach, beforeEach, context, describe, it} = global
{expect} = require 'chai'
MeshbluHttp = require 'meshblu-http'
MeshbluFirehose = require 'meshblu-firehose-socket.io'
enableDestroy = require 'server-destroy'
shmock = require 'shmock'
sinon = require 'sinon'

Verifier = require '../src/verifier'
MockMeshbluFirehoseSocketIO = require './mock-meshblu-firehose-socket-io'

describe 'Verifier', ->
  beforeEach ->
    @nonce = Date.now()
    @firehoseMessageHandler = sinon.stub()

  beforeEach ->
    @meshblu = shmock()
    enableDestroy @meshblu

  beforeEach (done) ->
    onConnection = (@firehoseSocket) =>
      @firehoseSocket.on 'error', (error) ->
        throw error

    @firehose = new MockMeshbluFirehoseSocketIO port: 0xd11d, onConnection: onConnection
    @firehose.start done

  afterEach 'stop the firehose', (done) ->
    @firehose.destroy done

  afterEach 'stop meshblu http', (done) ->
    @meshblu.destroy done

  describe '->verify', ->
    beforeEach ->
      firehose = new MeshbluFirehose meshbluConfig: {
        uuid: 'the-uuid'
        token: 'the-token'
        protocol: 'ws'
        hostname: 'localhost'
        port: 0xd11d
        resolveSrv: false
      }
      meshblu  = new MeshbluHttp {
        protocol: 'http'
        hostname: 'localhost'
        port: @meshblu.address().port
        resolveSrv: false
      }

      @sut = new Verifier {meshbluConfig: {}, @nonce}, {firehose, meshblu}

    context 'when everything works', ->
      beforeEach 'message succeeds', ->
        @sendMessage = @meshblu
          .post '/messages'
          .reply 201, {}

      beforeEach 'verify', (done) ->
        @sut.verify done

      it 'should have sent a message', ->
        expect(@sendMessage.isDone).to.be.true

    context 'when message fails', ->
      beforeEach (done) ->
        @sendMessage = @meshblu
          .post '/messages'
          .reply 500, {error: 'something wrong'}

        @sut.verify (@error) =>
          done()

      it 'should have sent a message', ->
        expect(@sendMessage.isDone).to.be.true

      it 'should error', ->
        expect(@error).to.exist
