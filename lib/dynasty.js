(function() {
  var Dynasty, Promise, Table, aws, debug, lib, typeToAwsType, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  aws = require('aws-sdk');

  _ = require('lodash');

  Promise = require('bluebird');

  debug = require('debug')('dynasty');

  typeToAwsType = {
    string: 'S',
    string_set: 'SS',
    number: 'N',
    number_set: 'NS',
    binary: 'B',
    binary_set: 'BS'
  };

  lib = require('./lib');

  Table = lib.Table;

  Dynasty = (function() {
    function Dynasty(credentials, url) {
      this.loadAllTables = __bind(this.loadAllTables, this);
      debug("dynasty constructed.");
      credentials.region = credentials.region || 'us-east-1';
      credentials.apiVersion = '2012-08-10';
      if (url && _.isString(url)) {
        debug("connecting to local dynamo at " + url);
        credentials.endpoint = new aws.Endpoint(url);
      }
      aws.config.update(credentials);
      this.dynamo = new aws.DynamoDB();
      Promise.promisifyAll(this.dynamo);
      this.name = 'Dynasty';
      this.tables = {};
    }

    Dynasty.prototype.loadAllTables = function() {
      return this.list().then((function(_this) {
        return function(data) {
          var tableName, _i, _len, _ref;
          _ref = data.TableNames;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            tableName = _ref[_i];
            _this.table(tableName);
          }
          return _this.tables;
        };
      })(this));
    };

    Dynasty.prototype.table = function(name) {
      return this.tables[name] = this.tables[name] || new Table(this, name);
    };


    /*
    Table Operations
     */

    Dynasty.prototype.alter = function(name, params, callback) {
      var awsParams, throughput;
      debug("alter() - " + name + ", " + (JSON.stringify(params, null, 4)));
      throughput = params.throughput || params;
      awsParams = {
        TableName: name,
        ProvisionedThroughput: {
          ReadCapacityUnits: throughput.read,
          WriteCapacityUnits: throughput.write
        }
      };
      return this.dynamo.updateTableAsync(awsParams).nodeify(callback);
    };

    Dynasty.prototype.create = function(name, params, callback) {
      var attributeDefinitions, awsParams, keySchema, throughput;
      if (callback == null) {
        callback = null;
      }
      debug("create() - " + name + ", " + (JSON.stringify(params, null, 4)));
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
      if (params.key_schema.range != null) {
        keySchema.push({
          KeyType: 'RANGE',
          AttributeName: params.key_schema.range[0]
        });
        attributeDefinitions.push({
          AttributeName: params.key_schema.range[0],
          AttributeType: typeToAwsType[params.key_schema.range[1]]
        });
      }
      awsParams = {
        AttributeDefinitions: attributeDefinitions,
        TableName: name,
        KeySchema: keySchema,
        ProvisionedThroughput: {
          ReadCapacityUnits: throughput.read,
          WriteCapacityUnits: throughput.write
        }
      };
      console.log("creating table with params " + (JSON.stringify(awsParams, null, 4)));
      return this.dynamo.createTableAsync(awsParams).nodeify(callback);
    };

    Dynasty.prototype.describe = function(name, callback) {
      debug("describe() - " + name);
      return this.dynamo.describeTableAsync({
        TableName: name
      }).nodeify(callback);
    };

    Dynasty.prototype.drop = function(name, callback) {
      var params;
      if (callback == null) {
        callback = null;
      }
      debug("drop() - " + name);
      params = {
        TableName: name
      };
      return this.dynamo.deleteTableAsync(params).nodeify(callback);
    };

    Dynasty.prototype.list = function(params, callback) {
      var awsParams;
      debug("list() - " + params);
      awsParams = {};
      if (params === !null) {
        if (_.isString(params)) {
          awsParams.ExclusiveStartTableName = params;
        } else if (_.isFunction(params)) {
          callback = params;
        } else if (_.isObject(params)) {
          if (params.limit === !null) {
            awsParams.Limit = params.limit;
          } else if (params.start === !null) {
            awsParams.ExclusiveStartTableName = params.start;
          }
        }
      }
      return this.dynamo.listTablesAsync(awsParams);
    };

    return Dynasty;

  })();

  module.exports = function(credentials, url) {
    return new Dynasty(credentials, url);
  };

}).call(this);
