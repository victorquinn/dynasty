_ = require('lodash')
dataTrans = require('./data-translators')
Promise = require('bluebird')

module.exports.processAllPages = (deferred, dynamo, functionName, params)->

  stats =
    Count: 0
      
  resultHandler = (err, result) ->
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
  @parent.dynamo.deleteItemAsync awsParams

module.exports.batchGetItem = (params, callback, keySchema) ->
  awsParams = {}
  awsParams.RequestItems = {}
  name = @name
  awsParams.RequestItems[@name] = Keys: _.map(params, (param) -> getKey(param, keySchema))
  @parent.dynamo.batchGetItemAsync(awsParams)
    .then (data) ->
      dataTrans.fromDynamo(data.Responses[name])
    .nodeify(callback)
    
module.exports.getItem = (params, options, callback, keySchema) ->
  awsParams =
    TableName: @name
    Key: getKey(params, keySchema)

  @parent.dynamo.getItemAsync(awsParams)
    .then (data)->
      dataTrans.fromDynamo(data.Item)
    .nodeify(callback)

module.exports.queryByHashKey = (key, callback, keySchema) ->
  awsParams =
    TableName: @name
    KeyConditions: {}

  hashKeyName = keySchema.hashKeyName
  hashKeyType = keySchema.hashKeyType

  awsParams.KeyConditions[hashKeyName] =
    ComparisonOperator: 'EQ'
    AttributeValueList: [{}]
  awsParams.KeyConditions[hashKeyName].AttributeValueList[0][hashKeyType] = key

  @parent.dynamo.queryAsync(awsParams)
    .then (data) ->
      dataTrans.fromDynamo(data.Items)
    .nodeify(callback)

module.exports.scan = (params, options, callback, keySchema) ->
  params ?= {}
  awsParams =
    TableName: @name
    ScanFilter: {}
    Select: 'SPECIFIC_ATTRIBUTES'
    AttributesToGet: params.attrsGet || [keySchema.hashKeyName]
    Limit: params.limit
    TotalSegments: params.totalSegment
    Segment: params.segment

  scanFilterFunc = (filter) ->
    obj = awsParams.ScanFilter
    obj[filter.column] =
      ComparisonOperator: filter.op || 'EQ'
      AttributeValueList: [{}]
    obj[filter.column].AttributeValueList[0][filter.type || 'S'] = filter.value
    obj

  if (params.filters)
    scanFilterFunc(filter) for filter in params.filters

  @parent.dynamo.scanAsync(awsParams)
    .then (data)->
      dataTrans.fromDynamo(data.Items)
    .nodeify(callback)

module.exports.putItem = (obj, options, callback) ->
  awsParams =
    TableName: @name
    Item: _.transform(obj, (res, val, key) ->
      res[key] = dataTrans.toDynamo(val))

  @parent.dynamo.putItemAsync(awsParams)
