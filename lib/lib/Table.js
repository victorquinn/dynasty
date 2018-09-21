(function() {
  var Table, _, awsTrans, dataTrans, debug;

  awsTrans = require('./aws-translators');

  dataTrans = require('./data-translators');

  _ = require('lodash');

  debug = require('debug')('dynasty');

  Table = class Table {
    constructor(parent, name) {
      this.parent = parent;
      this.name = name;
      this.key = this.describe().then(awsTrans.getKeySchema).then((keySchema) => {
        this.hasRangeKey = 4 === _.size(_.compact(_.values(keySchema)));
        return keySchema;
      });
    }

    /*
    Item Operations
    */
    // Wrapper around DynamoDB's batchGetItem
    batchFind(params, callback = null) {
      debug(`batchFind() - ${params}`);
      return this.key.then(awsTrans.batchGetItem.bind(this, params, callback));
    }

    findAll(params, callback = null) {
      debug(`findAll() - ${params}`);
      return this.key.then(awsTrans.queryByHashKey.bind(this, params, callback));
    }

    // Wrapper around DynamoDB's getItem
    find(params, options = {}, callback = null) {
      debug(`find() - ${params}`);
      return this.key.then(awsTrans.getItem.bind(this, params, options, callback));
    }

    // Wrapper around DynamoDB's scan
    scan(params, options = {}, callback = null) {
      debug(`scan() - ${params}`);
      return this.key.then(awsTrans.scan.bind(this, params, options, callback));
    }

    // Wrapper around DynamoDB's query
    query(params, options = {}, callback = null) {
      debug(`query() - ${params}`);
      return this.key.then(awsTrans.query.bind(this, params, options, callback));
    }

    // Wrapper around DynamoDB's putItem
    insert(obj, options = {}, callback = null) {
      debug("insert() - " + JSON.stringify(obj));
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      return this.key.then(awsTrans.putItem.bind(this, obj, options, callback));
    }

    remove(params, options, callback = null) {
      return this.key.then(awsTrans.deleteItem.bind(this, params, options, callback));
    }

    // Wrapper around DynamoDB's updateItem
    update(params, obj, options, callback = null) {
      debug("update() - " + JSON.stringify(obj));
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      return this.key.then(awsTrans.updateItem.bind(this, params, obj, options, callback));
    }

    /*
    Table Operations
    */
    // describe
    describe(callback = null) {
      debug('describe() - ' + this.name);
      return this.parent.dynamo.describeTablePromise({
        TableName: this.name
      }).nodeify(callback);
    }

    // drop
    drop(callback = null) {
      return this.parent.drop(this.name, callback);
    }

  };

  module.exports = Table;

}).call(this);
