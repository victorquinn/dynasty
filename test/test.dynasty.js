(function() {
  var Chance, Dynasty, Q, chance, expect, getCredentials, sinon;

  expect = require('chai').expect;

  Chance = require('chance');

  Dynasty = require('../dynasty');

  sinon = require('sinon');

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
        t = dynasty.table(chance.name());
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
        this.table = this.dynasty.table(chance.name());
        return this.dynamo = this.dynasty.dynamo;
      });
      describe('remove()', function() {
        var sandbox;
        sandbox = null;
        beforeEach(function() {
          return sandbox = sinon.sandbox.create();
        });
        afterEach(function() {
          return sandbox.restore();
        });
        it('should return an object', function() {
          var promise;
          promise = this.table.remove('foo');
          return expect(promise).to.be.an('object');
        });
        it('should return a promise which resolves deleteItem', function() {
          var promise;
          sandbox.stub(Q, "ninvoke").returns('lol');
          promise = this.table.remove('foo');
          return expect(promise).to.equal('lol');
        });
        it('should send the table name to AWS', function() {
          var params, promise;
          sandbox.spy(Q, "ninvoke");
          promise = this.table.remove('foo');
          expect(Q.ninvoke.calledOnce).to.equal(true);
          params = Q.ninvoke.getCall(0).args[2];
          return expect(params.TableName).to.equal(this.table.name);
        });
        it('should send the hash key to AWS', function() {
          var params, promise;
          sandbox.spy(Q, 'ninvoke');
          sandbox.stub(this.table, 'key').returns({
            hashKeyName: 'bar',
            hashKeyType: 'S'
          });
          promise = this.table.remove('foo');
          expect(Q.ninvoke.calledOnce).to.equal(true);
          params = Q.ninvoke.getCall(0).args[2];
          expect(params.Key).to.include.keys('bar');
          expect(params.Key.bar).to.include.keys('S');
          return expect(params.Key.bar.S).to.equal('foo');
        });
        return it('should send the hash and range key to AWS', function() {
          var params, promise;
          sandbox.spy(Q, 'ninvoke');
          sandbox.stub(this.table, 'key').returns({
            hashKeyName: 'bar',
            hashKeyType: 'S',
            rangeKeyName: 'foo',
            rangeKeyType: 'S'
          });
          promise = this.table.remove({
            hash: 'lol',
            range: 'rofl'
          });
          expect(Q.ninvoke.calledOnce).to.equal(true);
          params = Q.ninvoke.getCall(0).args[2];
          expect(params.Key).to.include.keys('bar');
          expect(params.Key.bar).to.include.keys('S');
          expect(params.Key.bar.S).to.equal('lol');
          expect(params.Key).to.include.keys('foo');
          expect(params.Key.foo).to.include.keys('S');
          return expect(params.Key.foo.S).to.equal('rofl');
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
