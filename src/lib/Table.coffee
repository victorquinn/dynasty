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

  # Wrapper around DynamoDB's getItem
  find: => 
    deferred = Q.defer() # Cannot be resolved until after @key
    promise = deferred.promise

    keyParam = {}
    awsParams =
      TableName: @name
      Key: keyParam

    hashKeySpecified = rangeKeySpecified = minRangeSpecified = false
    specifiedMinRange = null

    options = {}
    promise.options = (opts)->
      _.extend(options, opts)
      promise

    promise.hash = (hashKeyValue) =>
      @key.then (keySchema)->
        keyParam[keySchema.hashKeyName] = {}
        keyParam[keySchema.hashKeyName][keySchema.hashKeyType] = hashKeyValue+''
        hashKeySpecified = true

      promise.range = (rangeKeyValue)=>
        @key.then (keySchema)=>
          if !@hasRangeKey
            deferred.reject new Error "Specifying range key for table without range key"
          else
            keyParam[keySchema.rangeKeyName] = {}
            keyParam[keySchema.rangeKeyName][keySchema.rangeKeyType] = rangeKeyValue+''
            rangeKeySpecified = true
        promise

      promise.minRange = (minRange)=>
        @key.then (keySchema)=>
          if !@hasRangeKey
            deferred.reject new Error "Specifying minimum range key for table without range key"
          else
            minRangeSpecified = true
            specifiedMinRange = minRange
        promise


      promise

    # Wait a tick and then run the appropriate aws function
    process.nextTick =>
      @key.then (keySchema)=>
        if !promise.isRejected()
          debug "find() - #{JSON.stringify awsParams}"
          if rangeKeySpecified and @hasRangeKey or hashKeySpecified and !@hasRangeKey
            awsParams = _.pick _.extend(awsParams, options), 'AttributesToGet', 'TableName', 'Key', 'ConsistentRead', 'ReturnConsumedCapacity'
            Q.ninvoke(@parent.dynamo, 'getItem', awsParams)
            .then((data)-> 
              data = dataTrans.fromDynamo(data.Item)
              deferred.notify if data then [data] else []
              data
            )
            .then(deferred.resolve)
            .catch(deferred.reject)
          else if !rangeKeySpecified and !hashKeySpecified
            delete awsParams.Key
            awsParams = _.pick _.extend(awsParams, options),  'TableName', 'AttributesToGet', 'ExclusiveStartKey', 'Limit', 'ScanFilter', 'Segment', 'Select', 'TotalSegments', 'ReturnConsumedCapacity'
            awsTrans.processAllPages(deferred, @parent.dynamo, 'scan', awsParams)
          else if !rangeKeySpecified and @hasRangeKey
            awsParams.KeyConditions = {}
            awsParams.KeyConditions[keySchema.hashKeyName] = 
              AttributeValueList : [
                awsParams.Key[keySchema.hashKeyName]
              ]
              ComparisonOperator: 'EQ'
            delete awsParams.Key
            if minRangeSpecified
              awsParams.KeyConditions ?= {}
              awsParams.KeyConditions[keySchema.rangeKeyName] = 
                AttributeValueList : [
                  dataTrans.toDynamo(specifiedMinRange)
                ]
                ComparisonOperator: 'GT'
            awsParams = _.pick _.extend(awsParams, options),  'TableName', 'AttributesToGet', 'ConsistentRead', 'ExclusiveStartKey', 'IndexName', 'KeyConditions', 'Limit', 'ReturnConsumedCapacity', 'ScanIndexForward', 'Select'
            awsTrans.processAllPages(deferred, @parent.dynamo, 'query', awsParams)
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