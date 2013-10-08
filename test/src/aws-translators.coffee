chai = require('chai')
expect = chai.expect
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
Chance = require('chance')
lib = require('../lib/lib')["aws-translators"]
sinon = require('sinon')
Q = require('q')

chance = new Chance()

describe 'aws-translators', () ->
  describe '#getKeySchema', () ->
    it 'should parse out a hash key from an aws response', () ->
      hashKeyName = chance.word()
      result = lib.getKeySchema(
        Table:
          KeySchema:[
            AttributeName: hashKeyName
            KeyType: 'HASH'
          ]
          AttributeDefinitions: [
            AttributeName: hashKeyName
            AttributeType: 'N'
          ]
      )

      expect(result).to.have.property('hashKeyName')
      expect(result.hashKeyName).to.equal(hashKeyName)

      expect(result).to.have.property('hashKeyType')
      expect(result.hashKeyType).to.equal('N')

    it 'should parse out a range key from an aws response', () ->
      hashKeyName = chance.word()
      rangeKeyName = chance.word()
      result = lib.getKeySchema(
        Table:
          KeySchema:[
            {
              AttributeName: hashKeyName
              KeyType: 'HASH'
            },
            {
              AttributeName: rangeKeyName
              KeyType: 'RANGE'
            }
          ]
          AttributeDefinitions: [
            {
              AttributeName: hashKeyName
              AttributeType: 'S'
            },
            {
              AttributeName: rangeKeyName
              AttributeType: 'B'
            }
          ]
      )
  
  describe '#deleteItem', () ->

    dynastyTable = null
    sandbox = null

    beforeEach () ->
      sandbox = sinon.sandbox.create()
      dynastyTable =
        name: chance.name()
        parent:
          dynamo: {
            deleteItem: (params, callback) ->
              callback(null, true)
          }

    afterEach () ->
      sandbox.restore()

    it 'should return an object', () ->
      promise = lib.deleteItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(promise).to.be.an('object')

    it 'should return a promise', () ->
      sandbox.stub(Q, "ninvoke").returns('lol')

      promise = lib.deleteItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(promise).to.equal('lol')

    it 'should call deleteItem of aws', () ->
      sandbox.spy(Q, "ninvoke")

      lib.deleteItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(Q.ninvoke.calledOnce)
      expect(Q.ninvoke.getCall(0).args[0]).to.equal(dynastyTable.parent.dynamo)
      expect(Q.ninvoke.getCall(0).args[1]).to.equal('deleteItem')

    it 'should send the table name to AWS', (done) ->
      sandbox.spy(Q, "ninvoke")

      promise = lib.deleteItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      promise.then () ->
        expect(Q.ninvoke.calledOnce)
        params = Q.ninvoke.getCall(0).args[2]
        expect(params.TableName).to.equal(dynastyTable.name)
        done()
      .fail done

    it 'should send the hash key to AWS', () ->
      sandbox.spy(Q, 'ninvoke')

      promise = lib.deleteItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(Q.ninvoke.calledOnce)
      params = Q.ninvoke.getCall(0).args[2]
      expect(params.Key).to.include.keys('bar')
      expect(params.Key.bar).to.include.keys('S')
      expect(params.Key.bar.S).to.equal('foo')

    it 'should send the hash and range key to AWS', () ->
      sandbox.spy(Q, 'ninvoke')

      promise = lib.deleteItem.call(
        dynastyTable,
          hash: 'lol'
          range: 'rofl',
        null,
        null,
          hashKeyName: 'bar'
          hashKeyType: 'S'
          rangeKeyName: 'foo'
          rangeKeyType: 'S')

      expect(Q.ninvoke.calledOnce)
      params = Q.ninvoke.getCall(0).args[2]

      expect(params.Key).to.include.keys('bar')
      expect(params.Key.bar).to.include.keys('S')
      expect(params.Key.bar.S).to.equal('lol')

      expect(params.Key).to.include.keys('foo')
      expect(params.Key.foo).to.include.keys('S')
      expect(params.Key.foo.S).to.equal('rofl')

  describe '#getItem', () ->

    dynastyTable = null
    sandbox = null

    beforeEach () ->
      sandbox = sinon.sandbox.create()
      dynastyTable =
        name: chance.name()
        parent:
          dynamo: {
            getItem: (params, callback) ->
              callback(null, true)
          }

    afterEach () ->
      sandbox.restore()

    it 'should return an object', () ->
      promise = lib.getItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(promise).to.be.an('object')

    it 'should return a promise', () ->
      sandbox.stub(Q, "ninvoke").returns(Q.resolve('lol'))

      promise = lib.getItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(promise).to.eventually.equal('lol')

    it 'should call getItem of aws', () ->
      sandbox.spy(Q, "ninvoke")

      lib.getItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(Q.ninvoke.calledOnce)
      expect(Q.ninvoke.getCall(0).args[0]).to.equal(dynastyTable.parent.dynamo)
      expect(Q.ninvoke.getCall(0).args[1]).to.equal('getItem')

    it 'should send the table name to AWS', (done) ->
      sandbox.spy(Q, "ninvoke")

      promise = lib.getItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      promise.then () ->
        expect(Q.ninvoke.calledOnce)
        params = Q.ninvoke.getCall(0).args[2]
        expect(params.TableName).to.equal(dynastyTable.name)
        done()
      .fail done

    it 'should send the hash key to AWS', () ->
      sandbox.spy(Q, 'ninvoke')

      promise = lib.getItem.call(dynastyTable, 'foo', null, null,
        hashKeyName: 'bar'
        hashKeyType: 'S'
      )

      expect(Q.ninvoke.calledOnce)
      params = Q.ninvoke.getCall(0).args[2]
      expect(params.Key).to.include.keys('bar')
      expect(params.Key.bar).to.include.keys('S')
      expect(params.Key.bar.S).to.equal('foo')

    it 'should send the hash and range key to AWS', () ->
      sandbox.spy(Q, 'ninvoke')

      promise = lib.getItem.call(
        dynastyTable,
          hash: 'lol'
          range: 'rofl',
        null,
        null,
          hashKeyName: 'bar'
          hashKeyType: 'S'
          rangeKeyName: 'foo'
          rangeKeyType: 'S')

      expect(Q.ninvoke.calledOnce)
      params = Q.ninvoke.getCall(0).args[2]

      expect(params.Key).to.include.keys('bar')
      expect(params.Key.bar).to.include.keys('S')
      expect(params.Key.bar.S).to.equal('lol')

      expect(params.Key).to.include.keys('foo')
      expect(params.Key.foo).to.include.keys('S')
      expect(params.Key.foo.S).to.equal('rofl')

  describe '#putItem', () ->

    dynastyTable = null
    sandbox = null

    beforeEach () ->
      sandbox = sinon.sandbox.create()
      dynastyTable =
        name: chance.name()
        parent:
          dynamo: {
            putItem: (params, callback) ->
              callback(null, true)
          }

    afterEach () ->
      sandbox.restore()

    it 'should return an object', () ->
      promise = lib.putItem.call(dynastyTable, foo: 'bar', null, null)

      expect(promise).to.be.an('object')

    it 'should return a promise', () ->
      sandbox.stub(Q, "ninvoke").returns(Q.resolve('lol'))

      promise = lib.putItem.call(dynastyTable, foo: 'bar', null, null)

      expect(promise).to.eventually.equal('lol')

    it 'should call putItem of aws', () ->
      sandbox.spy(Q, "ninvoke")

      lib.putItem.call(dynastyTable, foo: 'bar', null, null)

      expect(Q.ninvoke.calledOnce)
      expect(Q.ninvoke.getCall(0).args[0]).to.equal(dynastyTable.parent.dynamo)
      expect(Q.ninvoke.getCall(0).args[1]).to.equal('putItem')

    it 'should send the table name to AWS', (done) ->
      sandbox.spy(Q, "ninvoke")

      promise = lib.putItem.call(dynastyTable, foo: 'bar', null, null)

      promise.then () ->
        expect(Q.ninvoke.calledOnce)
        params = Q.ninvoke.getCall(0).args[2]
        expect(params.TableName).to.equal(dynastyTable.name)
        done()
      .fail done

    it 'should send the translated object to AWS', () ->
      sandbox.spy(Q, 'ninvoke')

      promise = lib.putItem.call(dynastyTable, foo: 'bar', null, null)

      expect(Q.ninvoke.calledOnce)
      params = Q.ninvoke.getCall(0).args[2]
      expect(params.Item).to.be.an('object')
      expect(params.Item.foo).to.be.an('object')
      expect(params.Item.foo.S).to.equal('bar')
