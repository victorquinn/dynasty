# Main Dynasty Class

aws = require('aws-sdk')
dynamodb = require('dynamodb')
lib = require('./lib')
_ = require('lodash')
Q = require('q')
debug = require('debug')('dynasty')

# See http://vq.io/19EiASB
typeToAwsType =
  string: 'S'
  string_set: 'SS'
  number: 'N'
  number_set: 'NS'
  binary: 'B'
  binary_set: 'BS'

class Dynasty

  @generator: (credentials) ->
    if not (this instanceof Dynasty)
      return new Dynasty(credentials)

  constructor: (credentials) ->
    debug "dynasty constructed."
    credentials.region = credentials.region || 'us-east-1'

    # Lock API version
    credentials.apiVersion = '2012-08-10'

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

  # Alter an existing table. Wrapper around AWS updateTable
  alter: (name, params, callback) ->
    debug "alter() - #{name}, #{params}"
    # We'll except either an object with a key of throughput or just
    # an object with the throughput info
    throughput = params.throughput || params

    awsParams =
      TableName: name
      ProvisionedThroughput:
        ReadCapacityUnits: throughput.read
        WriteCapacityUnits: throughput.write

    promise = Q.ninvoke(@dynamo, 'updateTable', awsParams)

    if callback is not null
      promise = promise.nodeify(callback)

    promise

  # Create a new table. Wrapper around AWS createTable
  create: (name, params, callback = null) ->
    debug "create() - #{name}, #{params}"
    throughput = params.throughput || {read: 10, write: 5}

    keySchema = [
      KeyType: 'HASH'
      AttributeName: params.key_schema.hash[0]
    ]

    attributeDefinitions = [
      AttributeName: params.key_schema.hash[0]
      AttributeType: typeToAwsType[params.key_schema.hash[1]]
    ]

    awsParams =
      AttributeDefinitions: attributeDefinitions
      TableName: name
      KeySchema: keySchema
      ProvisionedThroughput:
        ReadCapacityUnits: throughput.read
        WriteCapacityUnits: throughput.write

    promise = Q.ninvoke(@dynamo, 'createTable', awsParams)

    if callback is not null
      promise = promise.nodeify(callback)

    promise


  # describe
  describe: (name, callback = null) ->
    debug "describe() - #{name}"
    promise = Q.ninvoke @dynamo, 'describeTable', TableName: name

    if callback is not null
      promise = promise.nodeify callback

    promise


  # Drop a table. Wrapper around AWS deleteTable
  drop: (name, callback = null) ->
    debug "drop() - #{name}"
    params =
      TableName: name

    promise = Q.ninvoke(@dynamo, 'deleteTable', params)

    if callback is not null
      promise = promise.nodeify(callback)

    promise

  # List tables. Wrapper around AWS listTables
  list: (params, callback) ->
    debug "list() - #{params}"
    awsParams = {}

    if params is not null
      if _.isString params
        awsParams.ExclusiveStartTableName = params
      else if _.isFunction params
        callback = params
      else if _.isObject params
        if params.limit is not null
          awsParams.Limit = params.limit
        else if params.start is not null
          awsParams.ExclusiveStartTableName = params.start

    promise = Q.ninvoke(@dynamo, 'listTables', awsParams)

    if callback is not null
      promise = promise.nodeify(callback)

    promise

  # See http://vq.io/19EiASB
  convert_to_dynamo: (item) ->
    if _.isArray item
      if _.every item, _.isNumber
        obj =
          'NS': item
      else if _.every item, _.isString
        if _.any(item, (i) -> i.length > 1024)
          obj =
            'BS': item
        else
          obj =
            'SS': item
      else
        stringify = _.map item, (i) -> JSON.stringify i
        obj =
          'BS': stringify
    else if _.isNumber item
      obj =
        'N': item.toString()
    else if _.isString item
      # Note: We're kind of arbitrarily defining that a Blob is a string greater
      # than 1024. This is a soft constraint from Amazon because a range key
      # cannot exceed 1024 but it is theoretically possible to store a string
      # greater than that as a string in DynamoDB.
      if item.length > 1024
        obj =
          'B': item
      else
        obj =
          'S': item
    else if _.isObject item
      # If it's an object, we will stringify it and put it into the DB as a blob
      obj =
        'B': JSON.stringify item
    else if not item
      throw new TypeError 'Cannot call convert_to_dynamo() with no arguments'




class Table

  constructor: (@parent, @name) ->
    @key = @describe().then lib.getKeySchema

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
    debug "find() - #{params}"
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
    debug "insert() - " + JSON.stringify obj
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

  remove: (params, options, callback = null) ->
    @key.then lib.deleteItem.bind(this, params, options, callback)

  ###
  Table Operations
  ###

  # describe
  describe: (callback = null) ->
    debug 'describe() - ' + @name
    promise = Q.ninvoke(@parent.dynamo, 'describeTable', TableName: @name)

    if callback is not null
      promise = promise.nodeify callback

    promise

  # drop
  drop: (callback = null) ->
    @parent.drop @name callback
    

module.exports = Dynasty.generator
