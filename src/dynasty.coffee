# Main Dynasty Class

aws = require('aws-sdk')
_ = require('lodash')
Promise = require('bluebird')
debug = require('debug')('dynasty')

# See http://vq.io/19EiASB
typeToAwsType =
  string: 'S'
  string_set: 'SS'
  number: 'N'
  number_set: 'NS'
  binary: 'B'
  binary_set: 'BS'

lib = require('./lib')
Table = lib.Table

class Dynasty

  constructor: (credentials, url) ->
    debug "dynasty constructed."
    credentials.region = credentials.region || 'us-east-1'

    # Lock API version
    credentials.apiVersion = '2012-08-10'

    if url and _.isString url
      debug "connecting to local dynamo at #{url}"
      credentials.endpoint = new aws.Endpoint url

    @dynamo = new aws.DynamoDB(credentials)
    Promise.promisifyAll @dynamo
    @name = 'Dynasty'
    @tables = {}

  loadAllTables: =>
    @list()
      .then (data) =>
        for tableName in data.TableNames
          @table(tableName)
        return @tables

  # Given a name, return a Table object
  table: (name) ->
    @tables[name] = @tables[name] || new Table this, name

  ###
  Table Operations
  ###

  # Alter an existing table. Wrapper around AWS updateTable
  alter: (name, params, callback) ->
    debug "alter() - #{name}, #{JSON.stringify(params, null, 4)}"
    # We'll accept either an object with a key of throughput or just
    # an object with the throughput info
    throughput = params.throughput || params

    awsParams =
      TableName: name
      ProvisionedThroughput:
        ReadCapacityUnits: throughput.read
        WriteCapacityUnits: throughput.write

    @dynamo.updateTableAsync(awsParams).nodeify(callback)

  # Create a new table. Wrapper around AWS createTable
  create: (name, params, callback = null) ->
    debug "create() - #{name}, #{JSON.stringify(params, null, 4)}"
    throughput = params.throughput || {read: 10, write: 5}

    keySchema = [
      KeyType: 'HASH'
      AttributeName: params.key_schema.hash[0]
    ]

    attributeDefinitions = [
      AttributeName: params.key_schema.hash[0]
      AttributeType: typeToAwsType[params.key_schema.hash[1]]
    ]

    if params.key_schema.range?
      keySchema.push
        KeyType: 'RANGE',
        AttributeName: params.key_schema.range[0]
      attributeDefinitions.push
        AttributeName: params.key_schema.range[0]
        AttributeType: typeToAwsType[params.key_schema.range[1]]

    awsParams =
      AttributeDefinitions: attributeDefinitions
      TableName: name
      KeySchema: keySchema
      ProvisionedThroughput:
        ReadCapacityUnits: throughput.read
        WriteCapacityUnits: throughput.write

    console.log "creating table with params #{JSON.stringify(awsParams, null, 4)}"

    @dynamo.createTableAsync(awsParams).nodeify(callback)

  # describe
  describe: (name, callback) ->
    debug "describe() - #{name}"
    @dynamo.describeTableAsync(TableName: name).nodeify(callback)

  # Drop a table. Wrapper around AWS deleteTable
  drop: (name, callback = null) ->
    debug "drop() - #{name}"
    params =
      TableName: name

    @dynamo.deleteTableAsync(params).nodeify(callback)

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

    @dynamo.listTablesAsync(awsParams)

module.exports = (credentials, url) -> new Dynasty(credentials, url)
