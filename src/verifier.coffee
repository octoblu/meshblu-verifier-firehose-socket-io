async   = require 'async'
MeshbluHttp = require 'meshblu-http'
MeshbluFirehose = require 'meshblu-firehose-socket.io'

ErrorReporter = require './error-reporter'

class Verifier
  constructor: ({@meshbluConfig, @nonce, @onError, @transports}, {@meshblu, @firehose}={}) ->
    @nonce    ?= Date.now()
    @meshblu  ?= new MeshbluHttp @meshbluConfig
    @firehose ?= new MeshbluFirehose { @meshbluConfig, transports: @transports }

  verify: (callback) =>
    async.series [
      @_connect
      @_message
      @_disconnect
    ], callback

  _connect: (callback) =>
    reporter = new ErrorReporter {callback}

    @firehose.once 'connect_error', reporter.report
    @firehose.once 'reconnect_error', reporter.report
    @firehose.connect reporter.report

  _disconnect: (callback) =>
    reporter = new ErrorReporter {callback}

    @firehose.once 'connect_error', reporter.report
    @firehose.once 'reconnect_error', reporter.report
    @firehose.close reporter.report

  _message: (callback) =>
    reporter = new ErrorReporter {callback}

    @firehose.once 'connect_error', reporter.report
    @firehose.once 'reconnect_error', reporter.report
    @firehose.once 'message', ({data}) =>
      return reporter.report(new Error 'wrong message received') unless data?.payload == @nonce
      reporter.report()

    message =
      devices: [@meshbluConfig.uuid]
      payload: @nonce

    @meshblu.message message, reporter.report

module.exports = Verifier
