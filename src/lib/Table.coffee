awsTrans = require('./aws-translators')
dataTrans = require('./data-translators')
_ = require('lodash')
debug = require('debug')('dynasty')

class Table

  constructor: (@parent, @name) ->
    @update = @insert
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

  findAll: (key, params, callback = null) ->
    debug "findAll() - #{params}"
    @key.then awsTrans.queryByHashKey.bind(this, key, params, callback)
    
  # Wrapper around DynamoDB's getItem
  find: (params, options = {}, callback = null) ->
    debug "find() - #{params}"
    @key.then awsTrans.getItem.bind(this, params, options, callback)

  # Wrapper around DynamoDB's scan
  scan: (params, options = {}, callback = null) ->
    debug "scan() - #{params}"
    @key.then awsTrans.scan.bind(this, params, options, callback)

  # Wrapper around DynamoDB's putItem
  insert: (obj, options = {}, callback = null) ->
    debug "insert() - " + JSON.stringify obj
    if _.isFunction options
      callback = options
      options = {}

    @key.then awsTrans.putItem.bind(this, obj, options, callback)

  remove: (params, options, callback = null) ->
    @key.then awsTrans.deleteItem.bind(this, params, options, callback)

  ###
  Table Operations
  ###

  # describe
  describe: (callback = null) ->
    debug 'describe() - ' + @name
    @parent.dynamo.describeTableAsync(TableName: @name).nodeify(callback)

  # drop
  drop: (callback = null) ->
    @parent.drop(@name, callback)

module.exports = Table
