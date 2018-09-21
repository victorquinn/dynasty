(function() {

  /*
     converts a DynamoDB compatible JSON object into
     a native JSON object
     @param dbObj the dynamodb JSON object
     @throws an error if input object is not compatible
     @return res the converted object
  */
  var _, convertObject, fromDynamo, toDynamo, util;

  _ = require('lodash');

  util = require('util');

  convertObject = function(obj) {
    var converted, key, value;
    converted = {};
    for (key in obj) {
      value = obj[key];
      converted[key] = fromDynamo(value);
    }
    return converted;
  };

  fromDynamo = function(dbObj) {
    var element, i, key, len, obj;
    if (_.isArray(dbObj)) {
      obj = [];
      for (key = i = 0, len = dbObj.length; i < len; key = ++i) {
        element = dbObj[key];
        obj[key] = fromDynamo(element);
      }
      return obj;
    }
    if (_.isObject(dbObj)) {
      if (dbObj.M) {
        return convertObject(dbObj.M);
      } else if ((dbObj.BOOL != null)) {
        return dbObj.BOOL;
      } else if (dbObj.S) {
        return dbObj.S;
      } else if (dbObj.SS) {
        return dbObj.SS;
      } else if ((dbObj.N != null)) {
        return parseFloat(dbObj.N);
      } else if (dbObj.NS) {
        return _.map(dbObj.NS, parseFloat);
      } else if (dbObj.L) {
        return _.map(dbObj.L, fromDynamo);
      } else if (dbObj.NULL) {
        return null;
      } else {
        return convertObject(dbObj);
      }
    } else {
      return dbObj;
    }
  };

  module.exports.fromDynamo = fromDynamo;

  // See http://vq.io/19EiASB
  toDynamo = function(item) {
    var array, i, key, len, map, obj, value;
    if (_.isArray(item)) {
      array = [];
      for (i = 0, len = item.length; i < len; i++) {
        value = item[i];
        array.push(toDynamo(value));
      }
      return obj = {
        'L': array
      };
    } else if (_.isNumber(item)) {
      return obj = {
        'N': item.toString()
      };
    } else if (_.isString(item)) {
      return obj = {
        'S': item
      };
    } else if (_.isBoolean(item)) {
      return obj = {
        'BOOL': item
      };
    } else if (_.isObject(item)) {
      map = {};
      for (key in item) {
        value = item[key];
        map[key] = toDynamo(value);
      }
      return obj = {
        'M': map
      };
    } else if (item === null) {
      return obj = {
        'NULL': true
      };
    } else if (!item) {
      throw new TypeError(`toDynamo() does not support mapping ${util.inspect(item)}`);
    }
  };

  module.exports.toDynamo = toDynamo;

}).call(this);
