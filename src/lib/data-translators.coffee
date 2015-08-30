_ = require('lodash')

###
   converts a DynamoDB compatible JSON object into
   a native JSON object
   @param ddb the ddb JSON object
   @throws an error if input object is not compatible
   @return res the converted object
###
module.exports.fromDynamo = (dbObj) ->
  if _.isArray dbObj
    for element, key in dbObj
      dbObj[key] = module.exports.fromDynamo element
    return dbObj
  if _.isObject dbObj
    return _.transform dbObj, (res, val, key) ->
      if(val.BOOL?)
        res[key] = val.BOOL
        return #NOTE: need this here since implied return would cause _.transform to cease operating for a false value when compiled to js
      else if(val.S)
        res[key] = val.S
      else if(val.SS)
        res[key] = val.SS
      else if(val.N)
        res[key] = parseFloat(val.N)
      else if(val.NS)
        res[key] = _.map(val.NS, parseFloat)
      else
        throw new Error('Non Compatible Field [not "S"|"N"|"NS"|"SS"]: ' + key)
  else
    return dbObj

# See http://vq.io/19EiASB
module.exports.toDynamo = (item) ->
  if _.isArray item
    if _.every item, _.isNumber
      obj =
        'NS': item
    else if _.every item, _.isString
      obj =
        'SS': item
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
    throw new TypeError 'Object is not serializable to a dynamo data type'
  else if not item
    throw new TypeError 'Cannot call convert_to_dynamo() with no arguments'
