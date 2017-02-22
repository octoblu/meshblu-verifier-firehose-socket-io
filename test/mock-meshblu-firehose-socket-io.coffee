http = require 'http'
SocketIO = require 'socket.io'
enableDestroy = require 'server-destroy'

class MockMeshbluFirehoseSocketIO
  constructor: (options) ->
    {onConnection, @port} = options

    @server = http.createServer()
    enableDestroy @server
    @io = SocketIO @server
    @io.on 'connection', onConnection

  start: (callback) =>
    @server.listen @port, callback

  when: (event, data) =>
    @io.on event, => return data

  destroy: (callback) =>
    @server.destroy callback

module.exports = MockMeshbluFirehoseSocketIO
