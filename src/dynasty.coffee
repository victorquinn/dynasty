# Main Dynasty Class

dynamodb = require('dynamodb')
_ = require('lodash')
Q = require('q')

class Dynasty

  @generator: (credentials) ->
    if not (this instanceof Dynasty)
      return new Dynasty(credentials)

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

  # Add some DRY
  init: (params, options, callback) ->
    if _.isFunction options
      callback = options
      options = {}

    if _.isString params
      hash = params
    else
      {hash, range} = params

    range = null if not range

    deferred = Q.defer()

    [hash, range, deferred, options, callback]

  ###
  Item Operations
  ###


  # Wrapper around DynamoDB's getItem
  find: (params, options = {}, callback = null) ->
    [hash, range, deferred, options, callback] = @init params, options, callback

    @parent.ddb.getItem @name, hash, range, options, (err, resp, cap) ->
      if err
        deferred.reject err
      else
        deferred.resolve resp
      callback(err, resp) if callback isnt null

    deferred.promise

  # Wrapper around DynamoDB's putItem
  insert: (obj, options = {}, callback = null) ->
    if _.isFunction options
      callback = options
      options = {}

    deferred = Q.defer()

    @parent.ddb.putItem @name, obj, options, (err, resp, cap) ->
      if err
        deferred.reject err
      else
        deferred.resolve resp
      callback(err, resp) if callback isnt null

    deferred.promise

  # Wrapper around DynamoDB's deleteItem
  remove: (params, options = {}, callback = null) ->
    [hash, range, options, callback] = @init params, options, callback

    @parent.ddb.deleteItem @name, hash, range, options, (err, resp, cap) ->
      if err
        deferred.reject err
      else
        deferred.resolve resp
      callback(err, resp) if callback isnt null

    deferred.promise

  ###
  Table Operations
  ###

  # create
  create: (params) ->
    {name, keyschema, throughput, callback} = params

    deferred = Q.defer()

    if throughput is null
      throughput =
        write: 10
        read: 10

    @ddb.createTable name, keyschema, throughput, (err, resp, cap) ->
      if err
        deferred.reject err
      else
        deferred.resolve resp
      callback(err, resp) if callback isnt null

    deferred.promise

  # drop
  drop: (params) ->
    # TODO
    

module.exports = Dynasty.generator
