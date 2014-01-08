_ = require('lodash')
dataTrans = require('./data-translators')
Q = require('q')

module.exports.processAllPages = (deferred, execute, functionName, params)->

  stats = 
    Count: 0
      
  resultHandler = (result, err)=>
    if err then return deferred.reject(err)

    deferred.notify dataTrans.fromDynamo result.Items
    stats.Count += result.Count
    if result.LastEvaluatedKey
      params.ExclusiveStartKey = result.LastEvaluatedKey
      execute(functionName, params).then(resultHandler)
    else
      deferred.resolve stats

  execute(functionName, params).then(resultHandler)
  deferred.promise


module.exports.getKeySchema = (tableDescription) ->
  keySchema = tableDescription.Table.KeySchema

  hashKeyName: keySchema.HashKeyElement.AttributeName
  hashKeyType: keySchema.HashKeyElement.AttributeType
  rangeKeyName: keySchema?.RangeKeyElement?.AttributeName
  rangeKeyType: keySchema?.RangeKeyElement?.AttributeType

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

