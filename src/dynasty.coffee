# Main Dynasty Class

dynamodb = require('dynamodb')
_ = require('underscore')
Q = require('Q')

class Dynasty

  constructor: (credentials) ->
    if credentials.region
      credentials.endpoint = "dynamodb.#{credentials.region}.amazonaws.com"

    @ddb = dynamodb.ddb credentials
    @name = 'Dynasty'
    @tables = {}

  # Given a name, return a Table object
  table: (name) ->
    @tables[name] = @tables[name] || new Table this, name

class Table

  constructor: (@parent, @name) ->

  # Wrapper around DynamoDB's getItem
  find: (params, opts = {}, callback = null) ->
    if _.isFunction opts
      callback = opts
      opts = {}

    deferred = Q.defer()

    if _.isString params
      hash = params
    else
      {hash, range} = params

    range = null if not range

    @parent.ddb.getItem @name, hash, range, opts, (err, resp, cap) ->
      if err
        deferred.reject(err)
      else
        deferred.resolve resp
      callback(err, resp) if callback isnt null

    deferred.promise


module.exports = Dynasty
