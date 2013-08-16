# Main Dynasty Class

aws = require('aws-sdk')
dynamodb = require('dynamodb')
_ = require('lodash')
Q = require('q')

typeToAwsType =
  string: 'S'
  number: 'N'
  byte: 'B'

class Dynasty

  @generator: (credentials) ->
    if not (this instanceof Dynasty)
      return new Dynasty(credentials)

  constructor: (credentials) ->

    if credentials.region
      credentials.endpoint = "dynamodb.#{credentials.region}.amazonaws.com"

    aws.config.update credentials

    @dynamo = new aws.DynamoDB()
    @ddb = dynamodb.ddb credentials
    @name = 'Dynasty'
    @tables = {}

  # Given a name, return a Table object
  table: (name) ->
    @tables[name] = @tables[name] || new Table this, name

  ###
  Table Operations
  ###

  create: (name, params, callback = null) ->
    throughput = params.throughput || {read: 10, write: 5}

    keySchema = [
      KeyType: 'HASH'
      AttributeName: params.key_schema.hash[0]
    ]

    attributeDefinitions = [
      AttributeName: params.key_schema.hash[0]
      AttributeType: typeToAwsType[params.keySchema.hash[1]]
    ]

    awsParams =
      TableName: name
      KeySchema: params.key_schema
      ProvisionedThroughput:
        ReadCapacityUnits: throughput.read
        WriteCapacityUnits: throughput.write

    promise = Q.nfcall(@dynamo.createTable, awsParams)

    if callback is not null
      promise = promise.nodeify(callback)

    promise

  drop: (name, callback = null) ->
    deferred = Q.defer()

    @ddb.deleteTable name, (err, resp, cap) ->
      if err
        deferred.reject err
      else
        deferred.resolve resp
      callback(err, resp) if callback isnt null

    deferred.promise

  alter: (name, params, callback) ->
    deferred = Q.defer()
    # We'll except either an object with a key of throughput or just
    # an object with the throughput info
    throughput = params.throughput || params

    @ddb.updateTable name, throughput, (err, resp, cap) ->
      if err
        deferred.reject err
      else
        deferred.resolve resp
      callback(err, resp) if callback isnt null

    deferred.promise


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
    [hash, range, deferred, options, callback] = @init params, options, callback

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

  # describe
  describe: (callback = null) ->
    promise = Q.nfcall(@parent.ddb.describeTable, @name)

    if callback is not null
      promise = promise.nodeify callback

    promise

  # drop
  drop: (params) ->
    # TODO
    

module.exports = Dynasty.generator
