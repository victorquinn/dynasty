chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
expect = require('chai').expect
Chance = require('chance')
Dynasty = require('../lib/dynasty')
_ = require('lodash')

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
      expect(require('../lib/dynasty')).to.be.a('function')

    it 'can construct', () ->
      dynasty = Dynasty(getCredentials())
      expect(dynasty).to.exist
      expect(dynasty.tables).to.exist

    it 'can retrieve a table object', () ->
      dynasty = Dynasty(getCredentials())
      t = dynasty.table chance.name()
      expect(t).to.be.an('object')

    describe 'create()', () ->

      beforeEach () ->
        @dynasty = Dynasty(getCredentials())

      it 'should return an object with valid key_schema', () ->
        promise = @dynasty.create chance.name(),
          key_schema:
            hash: [chance.name(), 'string']

        expect(promise).to.be.an('object')

      it 'should accept a hash and range key_schema', () ->
        promise = @dynasty.create chance.name(),
          key_schema:
            hash: [chance.name(), 'string']
            range: [chance.name(), 'string']

        expect(promise).to.be.an('object')

  describe 'Table', () ->

    beforeEach () ->
      @dynasty = Dynasty(getCredentials())
      @table = @dynasty.table chance.name()
      @dynamo = @dynasty.dynamo

    describe 'remove()', () ->

      it 'should return an object', () ->
        promise = @table.remove chance.name()
        expect(promise).to.be.an('object')

    describe 'batchFind()', () ->

      it 'works with an array of keys', () ->
        promise = @table.batchFind [chance.name()]
        expect(promise).to.be.an('object')

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

    describe 'alter()', () ->

      it 'should return an object', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')
