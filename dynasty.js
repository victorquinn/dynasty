(function() {
  var Dynasty, Q, Table, aws, dynamodb, lib, typeToAwsType, _;

  aws = require('aws-sdk');

  dynamodb = require('dynamodb');

  lib = require('./lib');

  _ = require('lodash');

  Q = require('q');

  typeToAwsType = {
    string: 'S',
    number: 'N',
    byte: 'B'
  };

  Dynasty = (function() {
    Dynasty.generator = function(credentials) {
      if (!(this instanceof Dynasty)) {
        return new Dynasty(credentials);
      }
    };

    function Dynasty(credentials) {
      if (credentials.region) {
        credentials.endpoint = "dynamodb." + credentials.region + ".amazonaws.com";
      }
      aws.config.update(credentials);
      this.dynamo = new aws.DynamoDB();
      this.ddb = dynamodb.ddb(credentials);
      this.name = 'Dynasty';
      this.tables = {};
    }

    Dynasty.prototype.table = function(name, describe) {
      return this.tables[name] = this.tables[name] || new Table(this, name);
    };

    /*
    Table Operations
    */


    Dynasty.prototype.create = function(name, params, callback) {
      var attributeDefinitions, awsParams, keySchema, promise, throughput;
      if (callback == null) {
        callback = null;
      }
      throughput = params.throughput || {
        read: 10,
        write: 5
      };
      keySchema = [
        {
          KeyType: 'HASH',
          AttributeName: params.key_schema.hash[0]
        }
      ];
      attributeDefinitions = [
        {
          AttributeName: params.key_schema.hash[0],
          AttributeType: typeToAwsType[params.key_schema.hash[1]]
        }
      ];
      awsParams = {
        AttributeDefinitions: attributeDefinitions,
        TableName: name,
        KeySchema: keySchema,
        ProvisionedThroughput: {
          ReadCapacityUnits: throughput.read,
          WriteCapacityUnits: throughput.write
        }
      };
      promise = Q.ninvoke(this.dynamo, 'createTable', awsParams);
      if (callback === !null) {
        promise = promise.nodeify(callback);
      }
      return promise;
    };

    Dynasty.prototype.drop = function(name, callback) {
      var params, promise;
      if (callback == null) {
        callback = null;
      }
      params = {
        TableName: name
      };
      promise = Q.ninvoke(this.dynamo, 'deleteTable', params);
      if (callback === !null) {
        promise = promise.nodeify(callback);
      }
      return promise;
    };

    Dynasty.prototype.alter = function(name, params, callback) {
      var deferred, throughput;
      deferred = Q.defer();
      throughput = params.throughput || params;
      this.ddb.updateTable(name, throughput, function(err, resp, cap) {
        if (err) {
          deferred.reject(err);
        } else {
          deferred.resolve(resp);
        }
        if (callback !== null) {
          return callback(err, resp);
        }
      });
      return deferred.promise;
    };

    return Dynasty;

  })();

  Table = (function() {
    function Table(parent, name) {
      this.parent = parent;
      this.name = name;
      this.key = this.describe().then(lib.getKeySchema);
    }

    Table.prototype.init = function(params, options, callback) {
      var deferred, hash, range;
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      if (_.isString(params)) {
        hash = params;
      } else {
        hash = params.hash, range = params.range;
      }
      if (!range) {
        range = null;
      }
      deferred = Q.defer();
      return [hash, range, deferred, options, callback];
    };

    /*
    Item Operations
    */


    Table.prototype.find = function(params, options, callback) {
      var deferred, hash, range, _ref;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      _ref = this.init(params, options, callback), hash = _ref[0], range = _ref[1], deferred = _ref[2], options = _ref[3], callback = _ref[4];
      this.parent.ddb.getItem(this.name, hash, range, options, function(err, resp, cap) {
        if (err) {
          deferred.reject(err);
        } else {
          deferred.resolve(resp);
        }
        if (callback !== null) {
          return callback(err, resp);
        }
      });
      return deferred.promise;
    };

    Table.prototype.insert = function(obj, options, callback) {
      var deferred;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      deferred = Q.defer();
      this.parent.ddb.putItem(this.name, obj, options, function(err, resp, cap) {
        if (err) {
          deferred.reject(err);
        } else {
          deferred.resolve(resp);
        }
        if (callback !== null) {
          return callback(err, resp);
        }
      });
      return deferred.promise;
    };

    Table.prototype.remove = function(params, options, callback) {
      if (callback == null) {
        callback = null;
      }
      return this.key.then(lib.deleteItem.bind(this, params, options, callback));
    };

    /*
    Table Operations
    */


    Table.prototype.describe = function(callback) {
      var promise;
      if (callback == null) {
        callback = null;
      }
      promise = Q.ninvoke(this.parent.dynamo, 'describeTable', {
        TableName: this.name
      });
      if (callback === !null) {
        promise = promise.nodeify(callback);
      }
      return promise;
    };

    Table.prototype.drop = function(callback) {
      if (callback == null) {
        callback = null;
      }
      return this.parent.drop(this.name(callback));
    };

    return Table;

  })();

  module.exports = Dynasty.generator;

}).call(this);
