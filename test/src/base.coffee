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


  describe 'Table', () ->

    beforeEach () ->
      @dynasty = Dynasty(getCredentials())
      @table = @dynasty.table chance.name()
      @dynamo = @dynasty.dynamo

    describe 'remove()', () ->

      it 'should return an object', () ->
        promise = @table.remove chance.name()
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

    describe 'convert_to_dynamo()', () ->

      it 'should throw an error if called with no arguments', () ->
        dynasty = @dynasty
        expect(() -> dynasty.convert_to_dynamo()).to.throw('Cannot call convert_to_dynamo() with no arguments')

      it 'looks right when given a number', () ->
        num = chance.integer()
        converted = @dynasty.convert_to_dynamo num
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'N': num.toString()

      it 'looks right when given a string', () ->
        str = chance.string()
        converted = @dynasty.convert_to_dynamo str
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'S': str

      it 'looks right when given a blob', () ->
        str = chance.string
          length: 1025
        converted = @dynasty.convert_to_dynamo str
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'B': str

      it 'looks right when given a random object', () ->
        obj = {}
        _.times 10, () ->
          obj[chance.string()] = chance.string()
        converted = @dynasty.convert_to_dynamo obj
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'B': JSON.stringify obj

      it 'looks right when given an array of numbers', () ->
        arr = chance.rpg '10d100'
        converted = @dynasty.convert_to_dynamo arr
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'NS': arr

      it 'looks right when given an array of strings', () ->
        arr = []
        _.times 10, () ->
          arr.push chance.string()
        converted = @dynasty.convert_to_dynamo arr
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'SS': arr

      it 'looks right when given an array of blobs', () ->
        arr = []
        _.times 10, () ->
          arr.push chance.string({length: 1040})
        converted = @dynasty.convert_to_dynamo arr
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'BS': arr

      it 'looks right when given an array of objects', () ->
        arr = []
        _.times 10, () ->
          obj = {}
          obj[chance.string()] = chance.string()
          arr.push obj

        stringified = _.map arr, (i) -> JSON.stringify i
        converted = @dynasty.convert_to_dynamo arr
        expect(converted).to.be.an 'object'
        expect(converted).to.deep.equal
          'BS': stringified
