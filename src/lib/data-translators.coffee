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
