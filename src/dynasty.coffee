# Main Dynasty Class

aws = require('aws-sdk')
awsTrans = require('./lib')["aws-translators"]
dataTrans = require('./lib')['data-translators']
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
    # We'll accept either an object with a key of throughput or just
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

class Table

  constructor: (@parent, @name) ->
    @update = @insert
    @key = @describe().then awsTrans.getKeySchema

  ###
  Item Operations
  ###

  # Wrapper around DynamoDB's getItem
  find: => 
    deferred = Q.defer() # Cannot be resolved until after @key
    promise = deferred.promise

    keyParam = {}
    awsParams =
      TableName: @name
      Key: keyParam

    promise.range = (rangeKeyValue)=>
      @key.then (keySchema)->
        if !keySchema.rangeKeyName
          deferred.reject new Error "Specifying range key for table without range key"
        else
          keyParam[keySchema.rangeKeyName] = {}
          keyParam[keySchema.rangeKeyName][keySchema.rangeKeyType] = rangeKeyValue+''
      promise

    promise.hash = (hashKeyValue) =>
      @key.then (keySchema)->
        keyParam[keySchema.hashKeyName] = {}
        keyParam[keySchema.hashKeyName][keySchema.hashKeyType] = hashKeyValue+''
      promise

    process.nextTick =>
      @key.then =>
        if !promise.isRejected()
          debug "find() - #{JSON.stringify awsParams}"
          Q.ninvoke(@parent.dynamo, 'getItem', awsParams)
          .then((data)-> dataTrans.fromDynamo(data.Item))
          .then(deferred.resolve)
          .catch(deferred.reject)

    promise


  # Wrapper around DynamoDB's putItem
  insert: (obj, options = {}, callback = null) ->
    debug "insert() - " + JSON.stringify obj
    if _.isFunction options
      callback = options
      options = {}

      awsTrans.putItem.bind(this, params, options, callback)

  remove: (params, options, callback = null) ->
    @key.then awsTrans.deleteItem.bind(this, params, options, callback)

  # TODO: Handle scan filters and pagination
  scan: (params, options, callback = null) ->
    debug "scan() - #{params}"
    params = {} if not params
    params.TableName = @name
    promise = Q.ninvoke @parent.dynamo, 'scan', params

    if callback is not null
      promise = promise.nodeify callback

    promise

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
