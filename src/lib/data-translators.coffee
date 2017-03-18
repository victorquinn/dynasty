_ = require('lodash')
util = require('util')
debug = require('debug')('dynasty:data-translators')

###
   converts a DynamoDB compatible JSON object into
   a native JSON object
   @param dbObj the dynamodb JSON object
   @throws an error if input object is not compatible
   @return res the converted object
###

# See http://vq.io/19EiASB
typeToAwsType =
  string: 'S'
  string_set: 'SS'
  number: 'N'
  number_set: 'NS'
  binary: 'B'
  binary_set: 'BS'

awsTypeToReadable =
  S: 'string'
  SS: 'string_set'
  N: 'number'
  NS: 'number_set'
  B: 'binary'
  BS: 'binary_set'
  BOOL: 'bool'
  L: 'list'
  M: 'map'
  NULL: 'null'

convertObject = (obj) ->
  converted = {}
  converted[key] = fromDynamo(value) for key, value of obj
  converted

fromDynamo = (dbObj) ->
  if _.isArray dbObj
    obj = []
    for element, key in dbObj
      obj[key] = fromDynamo element
    return obj
  if _.isObject dbObj
    if dbObj.M
      return convertObject(dbObj.M)
    else if(dbObj.BOOL?)
      return dbObj.BOOL
    else if(dbObj.S)
      return dbObj.S
    else if(dbObj.SS)
      return dbObj.SS
    else if(dbObj.N?)
      return parseFloat(dbObj.N)
    else if(dbObj.NS)
      return _.map(dbObj.NS, parseFloat)
    else if(dbObj.L)
      return _.map(dbObj.L, fromDynamo)
    else if(dbObj.NULL)
      return null
    else
      return convertObject(dbObj)
  else
    return dbObj

# See http://vq.io/19EiASB
toDynamo = (item) ->
  if _.isArray item
    if item.length > 0 and _.every item, _.isNumber
      obj =
        'NS': (num.toString() for num in item)
    else if item.length > 0 and _.every item, _.isString
      obj =
        'SS': item
    else if _.every item, _.isObject
      array = []
      for value in item
        array.push(toDynamo(value))
      obj =
        'L': array
    else
      throw new TypeError 'Expected homogenous array of numbers or strings'
  else if _.isNumber item
    obj =
      'N': item.toString()
  else if _.isString item
    obj =
      'S': item
  else if _.isBoolean item
    obj =
      'BOOL': item
  else if _.isObject item
    map = {}
    for key, value of item
      map[key] = toDynamo(value)
    obj =
      'M': map
  else if item is null
    obj =
      'NULL': true
  else if not item
    throw new TypeError "toDynamo() does not support mapping #{util.inspect(item)}"

keySchemaFromDynamo = (table, keySchema) ->
  convertedKeySchema = {}

  # First find hash
  hashRaw = table.AttributeDefinitions.find (val) ->
    val.AttributeName == table.KeySchema[0].AttributeName

  # Then translate this hash
  convertedKeySchema.hash = [ hashRaw.AttributeName, awsTypeToReadable[hashRaw.AttributeType] ]

  if keySchema.length == 2
    rangeRaw = table.AttributeDefinitions.find (val) ->
      val.AttributeName == table.KeySchema[1].AttributeName
    convertedKeySchema.range = [ rangeRaw.AttributeName, awsTypeToReadable[rangeRaw.AttributeType] ]

  convertedKeySchema

throughputFromDynamo = (table) ->
  write: table.ProvisionedThroughput.WriteCapacityUnits
  read: table.ProvisionedThroughput.ReadCapacityUnits
  last_increased_at: table.ProvisionedThroughput.LastIncreaseDateTime
  last_decreased_at: table.ProvisionedThroughput.LastDecreaseDateTime
  decreases_today: table.ProvisionedThroughput.NumberOfDecreasesToday

attributesFromDynamo = (table) ->
  table.AttributeDefinitions.map (attribute) ->
    [ attribute.AttributeName, awsTypeToReadable[attribute.AttributeType] ]

tableFromDynamo = (table) ->
  output =
    arn: table.TableArn
    attributes: attributesFromDynamo table
    bytes: table.TableSizeBytes
    count: table.ItemCount
    created_at: table.CreationDateTime
    key_schema: keySchemaFromDynamo table, table.KeySchema
    name: table.TableName
    status: table.TableStatus
    throughput: throughputFromDynamo table

module.exports =
  fromDynamo: fromDynamo
  keySchemaFromDynamo: keySchemaFromDynamo
  tableFromDynamo: tableFromDynamo
  throughputFromDynamo: throughputFromDynamo
  toDynamo: toDynamo
  typeToAwsType: typeToAwsType
