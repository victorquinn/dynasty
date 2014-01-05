awsTrans = require('./aws-translators')
_ = require('lodash')
Q = require('q')
debug = require('debug')('dynasty')

class Table

  constructor: (@parent, @name) ->
    @update = @insert
    @key = @describe().then awsTrans.getKeySchema

  ###
  Item Operations
  ###

  # Wrapper around DynamoDB's getItem
  find: (params, options = {}, callback = null) ->
    debug "find() - #{params}"
    @key.then awsTrans.getItem.bind(this, params, options, callback)

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
    
module.exports = Table