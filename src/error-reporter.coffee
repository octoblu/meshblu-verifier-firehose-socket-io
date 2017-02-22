_ = require 'lodash'

class ErrorReporter
  constructor: ({callback}) ->
    @callback = _.once callback

  report: (error) =>
    return @callback() unless error?
    error = new Error error if _.isString error
    error = new Error "#{error.message}: #{error.status}"
    error.code = error.status
    @callback error

module.exports = ErrorReporter
