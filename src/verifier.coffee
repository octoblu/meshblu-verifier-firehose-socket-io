_       = require 'lodash'
async   = require 'async'
Meshblu = require 'meshblu'
MeshbluFirehose = require 'meshblu-firehose-socket.io'

class Verifier
  constructor: ({@meshbluConfig, @onError, @nonce}) ->
    @nonce ?= Date.now()

  verify: (callback) =>
    async.series [
      @_connect
      @_message
    ], (error) =>
      @meshblu.close()
      callback error

  _connect: (callback) =>
    callback = _.once callback
    @meshblu = new Meshblu @meshbluConfig
    @firehose = new MeshbluFirehose { @meshbluConfig }
    @meshblu.once 'notReady', (error) =>
      error = new Error "Meshblu Error: #{error.status}"
      error.code = error.status
      callback error
    @meshblu.connect (error) =>
      return callback error if error?
      @firehose.connect callback

  _message: (callback) =>
    @firehose.once 'message', ({data}) =>
      return callback new Error 'wrong message received' unless data?.payload == @nonce
      callback()

    message =
      devices: [@meshbluConfig.uuid]
      payload: @nonce

    @meshblu.message message

module.exports = Verifier
