_ = require('lodash')
dataTrans = require('./data-translators')
Q = require('q')

module.exports.processAllPages = (deferred, dynamo, functionName, params)->

  stats =
    Count: 0
      
  resultHandler = (err, result)=>
    if err then return deferred.reject(err)

    deferred.notify dataTrans.fromDynamo result.Items
    stats.Count += result.Count
    if result.LastEvaluatedKey
      params.ExclusiveStartKey = result.LastEvaluatedKey
      dynamo[functionName] params, resultHandler
    else
      deferred.resolve stats

  dynamo[functionName] params, resultHandler
  deferred.promise


module.exports.getKeySchema = (tableDescription) ->
  getKeyAndType = (keyType) ->
    keyName = _.find tableDescription.Table.KeySchema, (key) ->
      key.KeyType is keyType
    ?.AttributeName

    keyDataType = _.find tableDescription.Table.AttributeDefinitions,
    (attribute) ->
      attribute.AttributeName is keyName
    ?.AttributeType
    [keyName, keyDataType]

  [hashKeyName, hashKeyType] = getKeyAndType 'HASH'
  [rangeKeyName, rangeKeyType] = getKeyAndType 'RANGE'

  hashKeyName: hashKeyName
  hashKeyType: hashKeyType
  rangeKeyName: rangeKeyName
  rangeKeyType: rangeKeyType

getKey = (params, keySchema) ->
  if !_.isObject params
    params = hash: params+''

  key = {}
  key[keySchema.hashKeyName] = {}
  key[keySchema.hashKeyName][keySchema.hashKeyType] = params.hash+''

  if params.range
    key[keySchema.rangeKeyName] = {}
    key[keySchema.rangeKeyName][keySchema.rangeKeyType] = params.range+''

  key

module.exports.deleteItem = (params, options, callback, keySchema) ->

  awsParams =
    TableName: @name
    Key: getKey(params, keySchema)

  promise = Q.ninvoke @parent.dynamo, 'deleteItem', awsParams

  if callback isnt null
    promise.nodeify(callback)

  promise

module.exports.batchGetItem = (params, callback = null) ->
  awsParams = {}
  awsParams[@name] = keys: params
  
  promise = Q.ninvoke(@parent.dynamo, 'batchGetItem', awsParams)
    
  if callback isnt null
    promise.nodeify(callback)

  promise
    
module.exports.getItem = (params, options, callback, keySchema) ->
  awsParams =
    TableName: @name
    Key: getKey(params, keySchema)

  promise = Q.ninvoke(@parent.dynamo, 'getItem', awsParams)
             .then (data)-> dataTrans.fromDynamo(data.Item)

  if callback isnt null
    promise.nodeify(callback)

  promise

module.exports.putItem = (obj, options, callback) ->
  awsParams =
    TableName: @name
    Item: _.transform(obj, (res, val, key) ->
      res[key] = dataTrans.toDynamo(val))

  promise = Q.ninvoke(@parent.dynamo, 'putItem', awsParams)

  if callback isnt null
    promise.nodeify(callback)

  promise
