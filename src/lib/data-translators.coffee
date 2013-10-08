_ = require('lodash')

###
   converts a DynamoDB compatible JSON object into
   a native JSON object
   @param ddb the ddb JSON object
   @throws an error if input object is not compatible
   @return res the converted object
###
module.exports.fromDynamo = (dbObj) ->
  if _.isObject dbObj
    return _.transform dbObj, (res, val, key) ->
      if(val.S)
        res[key] = val.S
      else if(val.SS)
        res[key] = val.SS
      else if(val.N)
        res[key] = parseFloat(val.N)
      else if(val.NS)
        res[key] = _.map(val.NS, parseFloat)
      else
        throw new Error('Non Compatible Field [not "S"|"N"|"NS"|"SS"]: ' + i)
  else
    return dbObj

# See http://vq.io/19EiASB
module.exports.toDynamo = (item) ->
    if _.isArray item
      if _.every item, _.isNumber
        obj =
          'NS': item
      else if _.every item, _.isString
        if _.any(item, (i) -> i.length > 1024)
          obj =
            'BS': item
        else
          obj =
            'SS': item
      else
        stringify = _.map item, (i) -> JSON.stringify i
        obj =
          'BS': stringify
    else if _.isNumber item
      obj =
        'N': item.toString()
    else if _.isString item
      # Note: We're kind of arbitrarily defining that a Blob is a string
      # greater than 1024. This is a soft constraint from Amazon because
      # a range key cannot exceed 1024 but it is theoretically possible to
      # store a string greater than that as a string in DynamoDB.
      if item.length > 1024
        obj =
          'B': item
      else
        obj =
          'S': item
    else if _.isObject item
      # If it's an object, we will stringify it and put it into the DB as
      # a blob
      obj =
        'B': JSON.stringify item
    else if not item
      throw new TypeError 'Cannot call convert_to_dynamo() with no arguments'
