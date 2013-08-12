# Main Dynasty Class

dynamodb = require('dynamodb')
_ = require('underscore')

class Dynasty

  constructor: (credentials) ->
    if credentials.region
      credentials.endpoint = "dynamodb.#{credentials.region}.amazonaws.com"

    @ddb = dynamodb.ddb credentials
    @tables = {}

  # Given a name, return a Table object
  table: (name) ->
    @tables[name] = @tables[name] || new Table this, name

class Table

  constructor: (@parent, @name) ->

  find: (opts, callback = null) ->
    if _.isString opts
      hash = opts
    else
      {hash, range} = opts

    console.log [hash, range]

module.exports = Dynasty
