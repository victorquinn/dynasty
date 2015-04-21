(function() {
  var _;

  _ = require('lodash');


  /*
     converts a DynamoDB compatible JSON object into
     a native JSON object
     @param ddb the ddb JSON object
     @throws an error if input object is not compatible
     @return res the converted object
   */

  module.exports.fromDynamo = function(dbObj) {
    var element, key, _i, _len;
    if (_.isArray(dbObj)) {
      for (key = _i = 0, _len = dbObj.length; _i < _len; key = ++_i) {
        element = dbObj[key];
        dbObj[key] = module.exports.fromDynamo(element);
      }
      return dbObj;
    }
    if (_.isObject(dbObj)) {
      return _.transform(dbObj, function(res, val, key) {
        if (val.S) {
          return res[key] = val.S;
        } else if (val.SS) {
          return res[key] = val.SS;
        } else if (val.N) {
          return res[key] = parseFloat(val.N);
        } else if (val.NS) {
          return res[key] = _.map(val.NS, parseFloat);
        } else {
          throw new Error('Non Compatible Field [not "S"|"N"|"NS"|"SS"]: ' + key);
        }
      });
    } else {
      return dbObj;
    }
  };

  module.exports.toDynamo = function(item) {
    var obj;
    if (_.isArray(item)) {
      if (_.every(item, _.isNumber)) {
        return obj = {
          'NS': item
        };
      } else if (_.every(item, _.isString)) {
        return obj = {
          'SS': item
        };
      } else {
        throw new TypeError('Expected homogenous array of numbers or strings');
      }
    } else if (_.isNumber(item)) {
      return obj = {
        'N': item.toString()
      };
    } else if (_.isString(item)) {
      return obj = {
        'S': item
      };
    } else if (_.isObject(item)) {
      throw new TypeError('Object is not serializable to a dynamo data type');
    } else if (!item) {
      throw new TypeError('Cannot call convert_to_dynamo() with no arguments');
    }
  };

}).call(this);
