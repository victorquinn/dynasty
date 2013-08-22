expect = require('chai').expect
Chance = require('chance')
Dynasty = require('../dynasty')
sinon = require('sinon')
Q = require('q')

chance = new Chance()

getCredentials = () ->
  accessKeyId: chance.string
    length: 20
    pool: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  secretAccessKey: chance.string
    length: 40

describe 'Dynasty', () ->
  describe 'Base', () ->
    it 'constructor exists and is a function', () ->
      expect(require('../dynasty')).to.be.a('function')

    it 'can construct', () ->
      dynasty = require('../dynasty')(getCredentials())
      expect(dynasty).to.exist
      expect(dynasty.tables).to.exist

    it 'can retrieve a table object', () ->
      dynasty = require('../dynasty')(getCredentials())
      t = dynasty.table chance.name(), () -> Q Table: {}
      expect(t).to.be.an('object')

    describe 'create()', () ->

      beforeEach () ->
        @dynasty = require('../dynasty')(getCredentials())

      it 'should return an object with valid key_schema', () ->
        promise = @dynasty.create chance.name(),
          key_schema:
            hash: [chance.name(), 'string']

        expect(promise).to.be.an('object')


  describe 'Table', () ->

    beforeEach () ->
      @dynasty = require('../dynasty')(getCredentials())
      @table = @dynasty.table chance.name(), () -> Q Table: {}
      @dynamo = @dynasty.dynamo

    describe 'remove()', () ->

      sandbox = null

      beforeEach () ->
        sandbox = sinon.sandbox.create()

      afterEach () ->
        sandbox.restore()

      it 'should return an object', () ->
        promise = @table.remove('foo')

        expect(promise).to.be.an('object')

      xit 'should return a promise which resolves deleteItem', () ->
        sandbox.stub(Q, "ninvoke").returns('lol')

        promise = @table.remove('foo')

        expect(promise).to.equal('lol')

      xit 'should send the table name to AWS', (done) ->
        sandbox.spy(Q, "ninvoke")

        promise = @table.remove('foo')

        promise.then () ->
          expect(Q.ninvoke.calledOnce).to.equal(true)
          params = Q.ninvoke.getCall(0).args[2]
          expect(params.TableName).to.equal(@table.name)
          done()
        .fail done

      xit 'should send the hash key to AWS', () ->
        sandbox.spy(Q, 'ninvoke')
        sandbox.stub(@table, 'key').returns
          hashKeyName: 'bar'
          hashKeyType: 'S'

        promise = @table.remove('foo')

        expect(Q.ninvoke.calledOnce).to.equal(true)
        params = Q.ninvoke.getCall(0).args[2]
        expect(params.Key).to.include.keys('bar')
        expect(params.Key.bar).to.include.keys('S')
        expect(params.Key.bar.S).to.equal('foo')

      xit 'should send the hash and range key to AWS', () ->
        sandbox.spy(Q, 'ninvoke')
        sandbox.stub(@table.key, 'then').callsArgWith
          hashKeyName: 'bar'
          hashKeyType: 'S'
          rangeKeyName: 'foo'
          rangeKeyType: 'S'

        promise = @table.remove
          hash: 'lol',
          range: 'rofl'

        expect(Q.ninvoke.calledOnce).to.equal(true)
        params = Q.ninvoke.getCall(0).args[2]

        expect(params.Key).to.include.keys('bar')
        expect(params.Key.bar).to.include.keys('S')
        expect(params.Key.bar.S).to.equal('lol')

        expect(params.Key).to.include.keys('foo')
        expect(params.Key.foo).to.include.keys('S')
        expect(params.Key.foo.S).to.equal('rofl')

    describe 'find()', () ->

      it 'works with just a string', () ->
        promise = @table.find chance.name()
        expect(promise).to.be.an('object')

      it 'works with an object with just a hash key', () ->
        promise = @table.find
          hash: chance.name()
        expect(promise).to.be.an('object')

      it 'works with an object with both a hash and range key', () ->
        promise = @table.find
          hash: chance.name()
          range: chance.name()
        expect(promise).to.be.an('object')

    describe 'describe()', () ->

      it 'should return an object', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')
