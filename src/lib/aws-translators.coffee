_ = require('lodash')
dataTrans = require('./data-translators')
Promise = require('bluebird')
debug = require('debug')('dynasty:aws-translators')

buildFilters = (target, filters) ->
  if filters
    scanFilterFunc(target, filter) for filter in filters

scanFilterFunc = (target, filter) ->
  target[filter.column] =
    ComparisonOperator: filter.op || 'EQ'
    AttributeValueList: [{}]
  target[filter.column].AttributeValueList[0][filter.type || 'S'] = filter.value
  target

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

module.exports.getKeySchema = (table) ->
  output =
    hashKeyName: table.key_schema.hash[0]
    hashKeyType: dataTrans.typeToAwsType[table.key_schema.hash[1]]

  if table.key_schema.hasOwnProperty("range")
    output['rangeKeyName'] = table.key_schema.range[0]
    output['rangeKeyType'] = dataTrans.typeToAwsType[table.key_schema.range[1]]
  else
    output['rangeKeyName'] = null
    output['rangeKeyType'] = null

  return output

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
    AttributesToGet: params.attrsGet || null
    Limit: params.limit
    TotalSegments: params.totalSegment
    Segment: params.segment

  if params.ExclusiveStartKey?
    awsParams.ExclusiveStartKey = {}
    for prop, val of params.ExclusiveStartKey
      awsParams.ExclusiveStartKey[prop] = dataTrans.toDynamo val

  buildFilters(awsParams.ScanFilter, params.filters)

  @parent.dynamo.scanAsync(awsParams)
    .then (data)->
      dataTrans.fromDynamo(data.Items)
    .nodeify(callback)

module.exports.query = (params, options, callback, keySchema) ->
  params ?= {}
  awsParams =
    TableName: @name
    IndexName: params.indexName
    KeyConditions: {}
    QueryFilter: {}

  buildFilters(awsParams.KeyConditions, params.keyConditions)
  buildFilters(awsParams.QueryFilter, params.filters)

  @parent.dynamo.queryAsync(awsParams)
    .then (data) ->
      dataTrans.fromDynamo(data.Items)
    .nodeify(callback)

module.exports.putItem = (obj, options, callback) ->
  awsParams =
    TableName: @name
    Item: _.transform(obj, (res, val, key) ->
      res[key] = dataTrans.toDynamo(val))

  @parent.dynamo.putItemAsync(awsParams)

module.exports.updateItem = (params, obj, options, callback, keySchema) ->
  key = getKey(params, keySchema)

  # Set up the Expression Attribute Values map.
  expressionAttributeValues = _.mapKeys obj, (value, key) -> return ':' + key
  expressionAttributeValues = _.mapValues expressionAttributeValues, (value, key) -> return dataTrans.toDynamo value

  # Setup ExpressionAttributeNames mapping key -> #key so we don't bump into
  # reserved words
  expressionAttributeNames = {}
  expressionAttributeNames["##{key}"] = key for key, i in Object.keys(obj)

  # Set up the Update Expression
  updateExpression = 'SET ' + _.keys(_.mapKeys obj, (value, key) -> "##{key} = :#{key}").join ','

  awsParams =
    TableName: @name
    Key: getKey(params, keySchema)
    ExpressionAttributeNames: expressionAttributeNames
    ExpressionAttributeValues: expressionAttributeValues
    UpdateExpression: updateExpression
  @parent.dynamo.updateItemAsync(awsParams)
