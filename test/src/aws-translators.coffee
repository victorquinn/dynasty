expect = require('chai').expect
Chance = require('chance')
lib = require('../lib')
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

