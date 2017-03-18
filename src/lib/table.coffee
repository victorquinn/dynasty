awsTrans = require('./aws-translators')
dataTrans = require('./data-translators')
_ = require('lodash')
debug = require('debug')('dynasty')

class Table

  constructor: (@parent, @name) ->
    @key = @describe().then(awsTrans.getKeySchema).then (keySchema)=>
      @hasRangeKey = (4 == _.size _.compact _.values keySchema)
      keySchema

  ###
  Item Operations
  ###

  # Wrapper around DynamoDB's batchGetItem
  batchFind: (params, callback = null) ->
    debug "batchFind() - #{params}"
    @key.then awsTrans.batchGetItem.bind(this, params, callback)

  findAll: (params, callback = null) ->
    debug "findAll() - #{params}"
    @key.then awsTrans.queryByHashKey.bind(this, params, callback)

  # Wrapper around DynamoDB's getItem
  find: (params, options = {}, callback = null) ->
    debug "find() - #{params}"
    if _.isFunction options
      callback = options
      options = {}

    @key.then awsTrans.getItem.bind(this, params, options, callback)

  # Wrapper around DynamoDB's scan
  scan: (params, options = {}, callback = null) ->
    debug "scan() - #{params}"
    @key.then awsTrans.scan.bind(this, params, options, callback)

  # Wrapper around DynamoDB's query
  query: (params, options = {}, callback = null) ->
    debug "query() - #{params}"
    @key.then awsTrans.query.bind(this, params, options, callback)

  # Wrapper around DynamoDB's putItem
  insert: (obj, options = {}, callback = null) ->
    debug "insert() - " + JSON.stringify obj
    if _.isFunction options
      callback = options
      options = {}

    @key.then awsTrans.putItem.bind(this, obj, options, callback)

  remove: (params, options, callback = null) ->
    @key.then awsTrans.deleteItem.bind(this, params, options, callback)

  # Wrapper around DynamoDB's updateItem
  update: (params, obj, options, callback = null) ->
    debug "update() - " + JSON.stringify obj
    if _.isFunction options
      callback = options
      options = {}

    @key.then awsTrans.updateItem.bind(this, params, obj, options, callback)

  ###
  Table Operations
  ###

  # Shortcut to run Describe and return a count of items in a table
  count: (callback = null) ->
    debug "count() - #{@name}"
    @parent
      .dynamo
      .describeTableAsync(TableName: @name)
      .then (resp) ->
        return resp.Table.ItemCount
      .nodeify(callback)

  # describe
  describe: (callback = null) ->
    debug 'describe() - ' + @name
    @parent
      .dynamo
      .describeTableAsync(TableName: @name)
      .then (resp) ->
        # Translate this response from Amazon to clean Dynasty version
        return dataTrans.tableFromDynamo resp.Table
      .nodeify(callback)

  # drop
  drop: (callback = null) ->
    @parent.drop(@name, callback)

module.exports = Table
