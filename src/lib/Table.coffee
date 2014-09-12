awsTrans = require('./aws-translators')
dataTrans = require('./data-translators')
_ = require('lodash')
Q = require('q')
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

  findAll: (params, callback = null) ->
    debug "findAll() - #{params}"
    @key.then awsTrans.queryByHashKey.bind(this, params, callback)
    
  # Wrapper around DynamoDB's getItem
  getItem: (params, options = {}, callback = null) ->
    debug "getItem() - #{params}"
    @key.then awsTrans.getItem.bind(this, params, options, callback)

  # Wrapper around DynamoDB's getItem which rejects if undefined
  find: (params, options = {}, callback = null) ->
    debug "find() - #{params}"
    promise = @getItem(params, options, null).then (data) ->
      throw new Error('Key not found') if _.isUndefined data
      data
    promise.nodeify callback if callback isnt null
    promise

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
    promise = Q.ninvoke(@parent.dynamo, 'describeTable', TableName: @name)
    promise.nodeify callback if callback isnt null
    promise

  # drop
  drop: (callback = null) ->
    @parent.drop @name callback

module.exports = Table
