(function() {
  var Chance, Q, chance, expect, lib, sinon;

  expect = require('chai').expect;

  Chance = require('chance');

  lib = require('../lib');

  sinon = require('sinon');

  Q = require('q');

  chance = new Chance();

  describe('aws-translators', function() {
    describe('#getKeySchema', function() {
      it('should parse out a hash key from an aws response', function() {
        var hashKeyName, result;
        hashKeyName = chance.word();
        result = lib.getKeySchema({
          Table: {
            KeySchema: [
              {
                AttributeName: hashKeyName,
                KeyType: 'HASH'
              }
            ],
            AttributeDefinitions: [
              {
                AttributeName: hashKeyName,
                AttributeType: 'N'
              }
            ]
          }
        });
        expect(result).to.have.property('hashKeyName');
        expect(result.hashKeyName).to.equal(hashKeyName);
        expect(result).to.have.property('hashKeyType');
        return expect(result.hashKeyType).to.equal('N');
      });
      return it('should parse out a range key from an aws response', function() {
        var hashKeyName, rangeKeyName, result;
        hashKeyName = chance.word();
        rangeKeyName = chance.word();
        return result = lib.getKeySchema({
          Table: {
            KeySchema: [
              {
                AttributeName: hashKeyName,
                KeyType: 'HASH'
              }, {
                AttributeName: rangeKeyName,
                KeyType: 'RANGE'
              }
            ],
            AttributeDefinitions: [
              {
                AttributeName: hashKeyName,
                AttributeType: 'S'
              }, {
                AttributeName: rangeKeyName,
                AttributeType: 'B'
              }
            ]
          }
        });
      });
    });
    return describe('#deleteItem', function() {
      var dynastyTable, sandbox;
      dynastyTable = null;
      sandbox = null;
      beforeEach(function() {
        sandbox = sinon.sandbox.create();
        return dynastyTable = {
          name: chance.name(),
          parent: {
            dynamo: {
              deleteItem: function(params, callback) {
                return callback(null, true);
              }
            }
          }
        };
      });
      afterEach(function() {
        return sandbox.restore();
      });
      it('should return an object', function() {
        var promise;
        promise = lib.deleteItem.call(dynastyTable, 'foo', null, null, {
          hashKeyName: 'bar',
          hashKeyType: 'S'
        });
        return expect(promise).to.be.an('object');
      });
      it('should return a promise', function() {
        var promise;
        sandbox.stub(Q, "ninvoke").returns('lol');
        promise = lib.deleteItem.call(dynastyTable, 'foo', null, null, {
          hashKeyName: 'bar',
          hashKeyType: 'S'
        });
        return expect(promise).to.equal('lol');
      });
      it('should call deleteItem of aws', function() {
        sandbox.spy(Q, "ninvoke");
        lib.deleteItem.call(dynastyTable, 'foo', null, null, {
          hashKeyName: 'bar',
          hashKeyType: 'S'
        });
        expect(Q.ninvoke.calledOnce);
        expect(Q.ninvoke.getCall(0).args[0]).to.equal(dynastyTable.parent.dynamo);
        return expect(Q.ninvoke.getCall(0).args[1]).to.equal('deleteItem');
      });
      it('should send the table name to AWS', function(done) {
        var promise;
        sandbox.spy(Q, "ninvoke");
        promise = lib.deleteItem.call(dynastyTable, 'foo', null, null, {
          hashKeyName: 'bar',
          hashKeyType: 'S'
        });
        return promise.then(function() {
          var params;
          expect(Q.ninvoke.calledOnce);
          params = Q.ninvoke.getCall(0).args[2];
          expect(params.TableName).to.equal(dynastyTable.name);
          return done();
        }).fail(done);
      });
      it('should send the hash key to AWS', function() {
        var params, promise;
        sandbox.spy(Q, 'ninvoke');
        promise = lib.deleteItem.call(dynastyTable, 'foo', null, null, {
          hashKeyName: 'bar',
          hashKeyType: 'S'
        });
        expect(Q.ninvoke.calledOnce);
        params = Q.ninvoke.getCall(0).args[2];
        expect(params.Key).to.include.keys('bar');
        expect(params.Key.bar).to.include.keys('S');
        return expect(params.Key.bar.S).to.equal('foo');
      });
      return it('should send the hash and range key to AWS', function() {
        var params, promise;
        sandbox.spy(Q, 'ninvoke');
        promise = lib.deleteItem.call(dynastyTable, {
          hash: 'lol',
          range: 'rofl'
        }, null, null, {
          hashKeyName: 'bar',
          hashKeyType: 'S',
          rangeKeyName: 'foo',
          rangeKeyType: 'S'
        });
        expect(Q.ninvoke.calledOnce);
        params = Q.ninvoke.getCall(0).args[2];
        expect(params.Key).to.include.keys('bar');
        expect(params.Key.bar).to.include.keys('S');
        expect(params.Key.bar.S).to.equal('lol');
        expect(params.Key).to.include.keys('foo');
        expect(params.Key.foo).to.include.keys('S');
        return expect(params.Key.foo.S).to.equal('rofl');
      });
    });
  });

}).call(this);

(function() {
  var Chance, Dynasty, Q, chance, expect, getCredentials;

  expect = require('chai').expect;

  Chance = require('chance');

  Dynasty = require('../dynasty');

  Q = require('q');

  chance = new Chance();

  getCredentials = function() {
    return {
      accessKeyId: chance.string({
        length: 20,
        pool: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      }),
      secretAccessKey: chance.string({
        length: 40
      })
    };
  };

  describe('Dynasty', function() {
    describe('Base', function() {
      it('constructor exists and is a function', function() {
        return expect(require('../dynasty')).to.be.a('function');
      });
      it('can construct', function() {
        var dynasty;
        dynasty = require('../dynasty')(getCredentials());
        expect(dynasty).to.exist;
        return expect(dynasty.tables).to.exist;
      });
      it('can retrieve a table object', function() {
        var dynasty, t;
        dynasty = require('../dynasty')(getCredentials());
        t = dynasty.table(chance.name(), function() {
          return Q({
            Table: {}
          });
        });
        return expect(t).to.be.an('object');
      });
      return describe('create()', function() {
        beforeEach(function() {
          return this.dynasty = require('../dynasty')(getCredentials());
        });
        return it('should return an object with valid key_schema', function() {
          var promise;
          promise = this.dynasty.create(chance.name(), {
            key_schema: {
              hash: [chance.name(), 'string']
            }
          });
          return expect(promise).to.be.an('object');
        });
      });
    });
    return describe('Table', function() {
      beforeEach(function() {
        this.dynasty = require('../dynasty')(getCredentials());
        this.table = this.dynasty.table(chance.name(), function() {
          return Q({
            Table: {}
          });
        });
        return this.dynamo = this.dynasty.dynamo;
      });
      describe('remove()', function() {
        return it('returns an object', function() {
          var promise;
          promise = this.table.remove(chance.name());
          return expect(promise).to.be.an('object');
        });
      });
      describe('find()', function() {
        it('works with just a string', function() {
          var promise;
          promise = this.table.find(chance.name());
          return expect(promise).to.be.an('object');
        });
        it('works with an object with just a hash key', function() {
          var promise;
          promise = this.table.find({
            hash: chance.name()
          });
          return expect(promise).to.be.an('object');
        });
        return it('works with an object with both a hash and range key', function() {
          var promise;
          promise = this.table.find({
            hash: chance.name(),
            range: chance.name()
          });
          return expect(promise).to.be.an('object');
        });
      });
      return describe('describe()', function() {
        return it('should return an object', function() {
          var promise;
          promise = this.table.describe();
          return expect(promise).to.be.an('object');
        });
      });
    });
  });

}).call(this);
