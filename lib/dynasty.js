(function() {
  // Main Dynasty Class
  var Dynasty, Promise, Table, _, aws, debug, https, lib, typeToAwsType;

  aws = require('aws-sdk');

  _ = require('lodash');

  Promise = require('bluebird');

  debug = require('debug')('dynasty');

  https = require('https');

  // See http://vq.io/19EiASB
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

  Dynasty = class Dynasty {
    constructor(credentials, url) {
      this.loadAllTables = this.loadAllTables.bind(this);
      debug("dynasty constructed.");
      credentials.region = credentials.region || 'us-east-1';
      // Lock API version
      credentials.apiVersion = '2012-08-10';
      if (url && _.isString(url)) {
        debug(`connecting to local dynamo at ${url}`);
        credentials.endpoint = new aws.Endpoint(url);
      }
      this.dynamo = new aws.DynamoDB(credentials);
      Promise.promisifyAll(this.dynamo, {
        suffix: 'Promise'
      });
      this.name = 'Dynasty';
      this.tables = {};
    }

    loadAllTables() {
      return this.list().then((data) => {
        var i, len, ref, tableName;
        ref = data.TableNames;
        for (i = 0, len = ref.length; i < len; i++) {
          tableName = ref[i];
          this.table(tableName);
        }
        return this.tables;
      });
    }

    // Given a name, return a Table object
    table(name) {
      return this.tables[name] = this.tables[name] || new Table(this, name);
    }

    /*
    Table Operations
    */
    // Alter an existing table. Wrapper around AWS updateTable
    alter(name, params, callback) {
      var awsParams, throughput;
      debug(`alter() - ${name}, ${JSON.stringify(params, null, 4)}`);
      // We'll accept either an object with a key of throughput or just
      // an object with the throughput info
      throughput = params.throughput || params;
      awsParams = {
        TableName: name,
        ProvisionedThroughput: {
          ReadCapacityUnits: throughput.read,
          WriteCapacityUnits: throughput.write
        }
      };
      return this.dynamo.updateTablePromise(awsParams).nodeify(callback);
    }

    // Create a new table. Wrapper around AWS createTable
    create(name, params, callback = null) {
      var attributeDefinitions, awsParams, i, index, j, keySchema, key_schema, keys, len, len1, ref, ref1, ref2, ref3, throughput, type, typesProvided;
      debug(`create() - ${name}, ${JSON.stringify(params, null, 4)}`);
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
      // Add GlobalSecondaryIndexes to awsParams if provided
      if (params.global_secondary_indexes != null) {
        awsParams.GlobalSecondaryIndexes = [];
        ref = params.global_secondary_indexes;
        // Verify valid GSI
        for (i = 0, len = ref.length; i < len; i++) {
          index = ref[i];
          key_schema = index.key_schema;
          // Must provide hash type
          if (key_schema.hash == null) {
            throw TypeError('Missing hash index for GlobalSecondaryIndex');
          }
          typesProvided = Object.keys(key_schema).length;
          // Provide 1-2 types for GSI
          if (typesProvided.length > 2 || typesProvided.length < 1) {
            throw RangeError('Expected one or two types for GlobalSecondaryIndex');
          }
          // Providing 2 types but the second isn't range type
          if (typesProvided.length === 2 && (key_schema.range == null)) {
            throw TypeError('Two types provided but the second isn\'t range');
          }
        }
        ref1 = params.global_secondary_indexes;
        // Push each index
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          index = ref1[j];
          keySchema = [];
          ref2 = index.key_schema;
          for (type in ref2) {
            keys = ref2[type];
            keySchema.push({
              AttributeName: keys[0],
              KeyType: type.toUpperCase()
            });
          }
          awsParams.GlobalSecondaryIndexes.push({
            IndexName: index.index_name,
            KeySchema: keySchema,
            Projection: {
              ProjectionType: index.projection_type.toUpperCase()
            },
            // Use the provided or default throughput
            ProvisionedThroughput: index.provisioned_throughput == null ? awsParams.ProvisionedThroughput : {
              ReadCapacityUnits: index.provisioned_throughput.read,
              WriteCapacityUnits: index.provisioned_throughput.write
            }
          });
          ref3 = index.key_schema;
          // Add key name to attributeDefinitions
          for (type in ref3) {
            keys = ref3[type];
            if (awsParams.AttributeDefinitions.filter(function(ad) {
              return ad.AttributeName === keys[0];
            }).length === 0) {
              awsParams.AttributeDefinitions.push({
                AttributeName: keys[0],
                AttributeType: typeToAwsType[keys[1]]
              });
            }
          }
        }
      }
      debug(`creating table with params ${JSON.stringify(awsParams, null, 4)}`);
      return this.dynamo.createTablePromise(awsParams).nodeify(callback);
    }

    // describe
    describe(name, callback) {
      debug(`describe() - ${name}`);
      return this.dynamo.describeTablePromise({
        TableName: name
      }).nodeify(callback);
    }

    // Drop a table. Wrapper around AWS deleteTable
    drop(name, callback = null) {
      var params;
      debug(`drop() - ${name}`);
      params = {
        TableName: name
      };
      return this.dynamo.deleteTablePromise(params).nodeify(callback);
    }

    // List tables. Wrapper around AWS listTables
    list(params, callback) {
      var awsParams;
      debug(`list() - ${params}`);
      awsParams = {};
      if (params !== null) {
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
      return this.dynamo.listTablesPromise(awsParams).nodeify(callback);
    }

  };

  module.exports = function(credentials, url) {
    return new Dynasty(credentials, url);
  };

}).call(this);
